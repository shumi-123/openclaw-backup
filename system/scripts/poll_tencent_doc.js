// Tencent Docs Polling Script - Wrapper for mcporter
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const FILE_ID = 'STaZDyqtgcHf';
const STATE_FILE = path.join(process.env.USERPROFILE, '.openclaw', '.tencent_doc_state');
const TRIGGER_FILE = path.join(process.env.USERPROFILE, '.openclaw', 'inbox', 'tencent-poll-trigger.txt');

try {
    // Get current document content via mcporter
    const output = execSync(
        `mcporter call tencent-docs get_content file_id=${FILE_ID}`,
        { encoding: 'utf8', timeout: 20000 }
    );

    const result = JSON.parse(output);
    const current = result.content || '';
    const currentHash = hashMD5(current);

    // Read last hash
    let lastHash = '';
    if (fs.existsSync(STATE_FILE)) {
        lastHash = fs.readFileSync(STATE_FILE, 'utf8').trim();
    }

    const timestamp = new Date().toISOString();

    if (currentHash !== lastHash) {
        console.log(`[${timestamp}] CHANGE DETECTED in document ${FILE_ID}`);

        // Save new hash
        fs.writeFileSync(STATE_FILE, currentHash, 'utf8');

        // Create trigger file
        const triggerContent = `TENCENT_DOC_POLL_${new Date().toISOString().replace(/[:.]/g, '')}
Document: ${FILE_ID}
Time: ${timestamp}
URL: https://docs.qq.com/aio/DU1RhWkR5cXRnY0hm
Status: NEW_MESSAGE_DETECTED
Content Length: ${current.length}
`;
        fs.writeFileSync(TRIGGER_FILE, triggerContent, 'utf8');
        console.log('Trigger file created: ' + TRIGGER_FILE);
    } else {
        console.log(`[${timestamp}] No change detected`);
    }
} catch (err) {
    console.error(`[ERROR] ${err.message}`);
    process.exit(1);
}

function hashMD5(str) {
    const crypto = require('crypto');
    return crypto.createHash('md5').update(str, 'utf8').digest('hex');
}
