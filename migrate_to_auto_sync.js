const fs = require('fs').promises; // Using promises for better async handling
const yaml = require('js-yaml');

const updateOrgManifestContent = (content) => {
    if (content.spec.syncPolicy.automated) return false;

    content.spec.syncPolicy.automated = { prune: true };
    content.spec.syncPolicy.syncOptions.push('Retry=true');
    content.spec.syncPolicy.retry = {
        limit: 10,
        backoff: {
            duration: '3s',
            factor: 2,
            maxDuration: '1m',
        },
    };

    return true;
};

const updateOrgRequirementsContent = (content) => {
    if (content.spec.syncPolicy.syncOptions) return false;

    content.spec.syncPolicy.syncOptions = ['Retry=true'];
    content.spec.syncPolicy.retry = {
        limit: 10,
        backoff: {
            duration: '3s',
            factor: 2,
            maxDuration: '1m',
        },
    };

    return true;
};

const updateIntegrationManifestContent = (content) => {
    if (content.spec.syncPolicy) return false;

    content.spec.syncPolicy = {
        automated: {
            prune: true,
        },
        syncOptions: ['Retry=true'],
        retry: {
            limit: 10,
            backoff: {
                duration: '3s',
                factor: 2,
                maxDuration: '1m',
            },
        },
    };

    return true;
};

const updateFileContent = async (filePath) => {
    try {
        const fileContent = await fs.readFile(filePath, 'utf8');
        const content = yaml.load(fileContent);
        let isChangeRequired;

        // Update content based on the filename
        if (filePath.endsWith('org-manifest.yml')) {
            isChangeRequired = updateOrgManifestContent(content);
        } else if (filePath.endsWith('org-requirements.yml')) {
            isChangeRequired = updateOrgRequirementsContent(content);
        } else {
            isChangeRequired = updateIntegrationManifestContent(content);
        }

        if (!isChangeRequired) return;

        // Write the modified content back to the file
        const newContent = yaml.dump(content);
        await fs.writeFile(filePath, newContent, 'utf8');
        console.log(`Updated: ${filePath}`);
    } catch (err) {
        console.error(`Error processing file ${filePath}: ${err}`);
    }
};

const iterateFiles = async (path = process.cwd()) => {
    try {
        const files = await fs.readdir(path, { withFileTypes: true });
        await Promise.all(files.map(async (file) => {
            const fullPath = `${path}/${file.name}`;
            if (file.isDirectory()) {
                await iterateFiles(fullPath); // Recursively process directories
            } else if (file.name.endsWith('.yml')) {
                await updateFileContent(fullPath); // Process YAML files
            }
        }));
    } catch (err) {
        console.error(`Error reading directory: ${err}`);
    }
};

iterateFiles().catch(err => console.error(`Failed to process files: ${err}`));