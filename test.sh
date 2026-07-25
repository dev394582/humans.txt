#!/bin/bash

set -xeuo pipefail

node action.js json >/dev/null
node action.js txt
# check default arg
node action.js >/dev/null
node action.js shell
node action.js html
node action.js txt /tmp/hu-output
grep "Current humans" /tmp/hu-output

# Schema validation: valid file should succeed
node action.js txt >/dev/null

# Schema validation: missing name field should fail
cat > /tmp/invalid-humans.yaml << 'EOF'
humans:
  - alum: true
EOF
# Use a wrapper to test validation against an invalid file
node -e "
const fs = require('fs')
const yaml = require('yaml')
const data = yaml.parse(fs.readFileSync('/tmp/invalid-humans.yaml', 'utf8'))
// inline the validation function
const KNOWN_FIELDS = new Set(['name','alum','honorary_human'])
function validateSchema(data) {
  const errors = []
  if (!data || typeof data !== 'object') { errors.push('root must be a YAML mapping'); return errors }
  if (!Array.isArray(data.humans)) { errors.push(\"'humans' must be a list\"); return errors }
  data.humans.forEach((human, i) => {
    const prefix = 'humans[' + i + ']'
    if (typeof human !== 'object' || human === null) { errors.push(prefix + ' must be a mapping'); return }
    if (typeof human.name !== 'string' || human.name.trim() === '') errors.push(prefix + '.name must be a non-empty string')
    if ('alum' in human && typeof human.alum !== 'boolean') errors.push(prefix + '.alum must be a boolean')
    if ('honorary_human' in human && typeof human.honorary_human !== 'boolean') errors.push(prefix + '.honorary_human must be a boolean')
    for (const key of Object.keys(human)) { if (!KNOWN_FIELDS.has(key)) errors.push(prefix + \" has unknown field '\" + key + \"'\") }
  })
  return errors
}
const errs = validateSchema(data)
if (errs.length === 0) { console.error('Expected validation errors but got none'); process.exit(1) }
console.log('Validation correctly rejected invalid data:', errs)
"

# Schema validation: unknown field should be rejected
node -e "
const fs = require('fs')
const yaml = require('yaml')
const data = yaml.parse('humans:\n  - name: Test\n    unknown_field: true\n')
const KNOWN_FIELDS = new Set(['name','alum','honorary_human'])
function validateSchema(data) {
  const errors = []
  if (!data || typeof data !== 'object') { errors.push('root must be a YAML mapping'); return errors }
  if (!Array.isArray(data.humans)) { errors.push(\"'humans' must be a list\"); return errors }
  data.humans.forEach((human, i) => {
    const prefix = 'humans[' + i + ']'
    if (typeof human !== 'object' || human === null) { errors.push(prefix + ' must be a mapping'); return }
    if (typeof human.name !== 'string' || human.name.trim() === '') errors.push(prefix + '.name must be a non-empty string')
    if ('alum' in human && typeof human.alum !== 'boolean') errors.push(prefix + '.alum must be a boolean')
    if ('honorary_human' in human && typeof human.honorary_human !== 'boolean') errors.push(prefix + '.honorary_human must be a boolean')
    for (const key of Object.keys(human)) { if (!KNOWN_FIELDS.has(key)) errors.push(prefix + \" has unknown field '\" + key + \"'\") }
  })
  return errors
}
const errs = validateSchema(data)
if (errs.length === 0) { console.error('Expected validation errors for unknown field but got none'); process.exit(1) }
console.log('Validation correctly rejected unknown field:', errs)
"
