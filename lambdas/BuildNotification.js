'use strict';

const AWS = require('aws-sdk');
const url = require('url');
const https = require('https');

const targetStage = process.env.TARGET_STAGE;

let stageMessages;

const colorMap = {
  FAILED: 'danger',
  SUCCEEDED: 'good',
}

const emoticonMap = {
  FAILED: ':skull:',
  SUCCEEDED: ':success:',
}

function callbackToPromise(resolve, reject) {
  return function(error, data) {
    if (error) {
      reject(error);
    }
    resolve(data);
  }
}

function getCommitInfo(event) {
  const params = {
    pipelineExecutionId: event.detail['execution-id'],
    pipelineName: event.detail.pipeline,
  }
  const codepipeline = new AWS.CodePipeline();

  return new Promise((resolve, reject) => {
    codepipeline.getPipelineExecution(params, callbackToPromise(resolve, reject))
  })
  .then(pipelineInfo => pipelineInfo.pipelineExecution.artifactRevisions.filter(rev => rev.name === 'App')[0])
  .then(uglyInfo => ({
      commitUrl: uglyInfo.revisionUrl,
      shortSha: uglyInfo.revisionId.substring(0, 7),
      commitMessage: uglyInfo.revisionSummary,
  }));
}

function generateStatusAttachment(event) {
  return getCommitInfo(event)
  .then(commitInfo => {
    const returner = {
      title: `Build ${event.detail.state} ${emoticonMap[event.detail.state]}`,
      color: `${colorMap[event.detail.state]}`,
      fields: [
        {
          title: 'Repo',
          value: process.env.REPO,
          short: true
        },
        {
          title: 'Branch',
          value: process.env.BRANCH,
          short: true
        },
        {
          title: 'Commit',
          value: `<${commitInfo.commitUrl}|${commitInfo.shortSha}>`,
          short: true
        },
        {
          title: 'Commit Message',
          value: commitInfo.commitMessage,
          short: true
        }
      ]
    }
    returner.fields.push({
      title: 'Reports',
      value: `<${process.env.REPORTS_URL}|Build Reports>`,
      short: true
    })
    returner.fields.push({
      title: 'Build Pipeline',
      value: `<${process.env.PIPELINE_URL}|CodePipeline Console>`,
      short: true
    })

    return returner;
  });
}

function getText(event) {
  const stage = event.detail.stage;
  const status = event.detail.state;
  // Reuse container if possible.
  if (!stageMessages) {
    stageMessages = {
      _default: {
        SUCCEEDED: 'You should not even see this message',
        FAILED: 'The build failed at Stage: *[<stage>]*'
      }
    }
    process.env.TARGET_STAGES.split(';').forEach(targetStage => {
      stageMessages[targetStage] = {
        SUCCEEDED: `Successfully deployed to *[${targetStage}]*`,
      }
    });
  }
  if (stageMessages[stage] && stageMessages[stage][status]) {
    return stageMessages[stage][status];
  }
  const returnMessage = stageMessages._default[status];
  return returnMessage.split('<stage>').join(stage);
}

function capitalize(word) {
  const firstLetter = word[0];
  const restOfTheWord = word.substring(1);
  return `${firstLetter.toUpperCase()}${restOfTheWord}`;
}


function getMessage(event) {
  return generateStatusAttachment(event)
  .then(attachment => {
    const returner = {
      text: getText(event),
      attachments: [attachment]
    };
    if (process.env.SLACK_CHANNEL) {
      returner.channel = process.env.SLACK_CHANNEL;
    }
    if (process.env.OWNER && process.env.PROJECT) {
      returner.username = `${capitalize(process.env.OWNER)}'s ${capitalize(process.env.PROJECT)} Pipeline`;
    }
    return returner;
  });
}

function postMessage(message) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(message);
    const options = url.parse(process.env.HOOK_URL);
    options.method = 'POST';
    options.headers = {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
    };

    const postReq = https.request(options, (res) => {
        const chunks = [];
        res.setEncoding('utf8');
        res.on('data', (chunk) => chunks.push(chunk));
        res.on('end', () => resolve( { body: chunks.join(''), statusCode: res.statusCode, statusMessage: res.statusMessage }));
        return res;
    });

    postReq.write(body);
    postReq.end();
  });
}

function processEvent(event, callback) {
  if (event.detail.stage && !event.detail.action) {
    return getMessage(event)
    .then(postMessage)
    .then(response => {
      if (response.statusCode < 400) {
        console.info('Message posted successfully');
        callback(null);
      } else if (response.statusCode < 500) {
          console.error(`Error posting message to Slack API: ${response.statusCode} - ${response.statusMessage}`);
          callback(null);  // Don't retry because the error is due to a problem with the request
      } else {
          // Let Lambda retry
          callback(`Server error when processing message: ${response.statusCode} - ${response.statusMessage}`);
      }
    })
    .catch(error => {
      callback(`Error: ${error.message}`)
    });
  }
  callback(null);
}

exports.handler = (event, context, callback) => {
    if (process.env.HOOK_URL) {
        processEvent(event, callback);
    } else {
        callback('Hook URL has not been set.');
    }
};
