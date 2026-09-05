const http = require('http');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: 'd:/Projects/Anitgraviy/amia fest/backend/.env' });

const API_BASE = 'http://localhost:3000/api';
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

function request(urlPath, method, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(API_BASE + urlPath);
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const req = http.request(url, { method, headers }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

(async () => {
  console.log('=== STARTING TEAM AUDIT & END-TO-END TEST ===\n');

  // Step 1: Login as Controller
  console.log('1. Logging in as Controller (ksams)...');
  const loginRes = await request('/auth/login', 'POST', {
    username: process.env.CONTROLLER_USERNAME || 'ksams',
    password: process.env.CONTROLLER_PASSWORD || 'Acsmr@7012'
  });

  const token = loginRes.data?.data?.accessToken || loginRes.data?.data?.token;
  if (loginRes.status !== 200 || !token) {
    console.error('FAILED LOGIN:', loginRes);
    process.exit(1);
  }
  console.log('SUCCESS: Controller logged in, JWT obtained.\n');

  // Step 2: GET teams
  console.log('2. GET /api/controller/teams...');
  const getTeamsRes = await request('/controller/teams', 'GET', null, token);
  console.log(`HTTP Status: ${getTeamsRes.status}`);
  const teams = getTeamsRes.data?.data || [];
  console.log(`Fetched ${teams.length} teams:`);
  console.log(JSON.stringify(teams, null, 2));

  // Step 3: Edit Apex (team_01)
  console.log('\n3. Editing Apex Team (team_01)...');
  const updateApexRes = await request('/controller/teams/team_01', 'PUT', {
    teamName: 'Apex',
    teamCode: 'T01',
    leaderName: 'SHAHIL K',
    assistantLeaderName: 'HASHIM FARHAN',
    mentorName: 'USTHAD SHAHEER HUDAWI'
  }, token);

  console.log(`Update Apex HTTP Status: ${updateApexRes.status}`);
  console.log('Update Apex Response:', JSON.stringify(updateApexRes.data, null, 2));

  if (updateApexRes.status !== 200) {
    console.error('FAILED TO UPDATE APEX TEAM');
    process.exit(1);
  }

  // Step 4: Verify Apex in Supabase directly
  const { data: dbApex } = await supabase.from('teams').select('*').eq('id', 'team_01').single();
  console.log('Supabase Apex DB Record:', JSON.stringify(dbApex, null, 2));

  // Step 5: Edit Telos (team_02)
  console.log('\n5. Editing Telos Team (team_02)...');
  const updateTelosRes = await request('/controller/teams/team_02', 'PUT', {
    teamName: 'Telos',
    teamCode: 'T02',
    leaderName: 'ALTHAF HUSSAIN',
    assistantLeaderName: 'IHSAN',
    mentorName: 'USTHAD NIZAM FAIZY'
  }, token);

  console.log(`Update Telos HTTP Status: ${updateTelosRes.status}`);
  console.log('Update Telos Response:', JSON.stringify(updateTelosRes.data, null, 2));

  if (updateTelosRes.status !== 200) {
    console.error('FAILED TO UPDATE TELOS TEAM');
    process.exit(1);
  }

  // Step 6: Verify Telos in Supabase directly
  const { data: dbTelos } = await supabase.from('teams').select('*').eq('id', 'team_02').single();
  console.log('Supabase Telos DB Record:', JSON.stringify(dbTelos, null, 2));

  // Step 7: Verify final teams list from API
  console.log('\n7. Final GET /api/controller/teams verification...');
  const finalGetRes = await request('/controller/teams', 'GET', null, token);
  console.log(`HTTP Status: ${finalGetRes.status}`);
  console.log('Final Teams List:', JSON.stringify(finalGetRes.data?.data, null, 2));

  console.log('\n=== AUDIT AND TEST COMPLETED SUCCESSFULLY ===');
})();
