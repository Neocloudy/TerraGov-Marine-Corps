import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Input,
  LabeledControls,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const OverwatchConsole = (props) => {
  const { act, data } = useBackend();

  return (
    <Window width={800} height={600} theme={data.theme}>
      <Window.Content>
        {(!data.current_squad && <HomePanel />) || <SquadPanel />}
      </Window.Content>
    </Window>
  );
};

const HomePanel = (props) => {
  const { act, data } = useBackend();

  return (
    <Section
      fontSize="20px"
      textAlign="center"
      title="OVERWATCH CURRENTLY OFFLINE"
    >
      <Stack justify="center" align="end" fontSize="20px">
        {data.watchable_squads.map((squad, index) => {
          return (
            <Stack.Item key={index}>
              <Button onClick={() => act('pick_squad', { picked: squad })}>
                {squad.toUpperCase()}
              </Button>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
};

const SquadPanel = (props) => {
  const { act, data } = useBackend();

  const [category, setCategory] = useLocalState('selected', 'monitor');

  return (
    <>
      <Collapsible title="Main Dashboard" fontSize="16px">
        <MainDashboard />
      </Collapsible>
      <Collapsible title="Squad Roles" fontSize="16px">
        <RoleTable />
      </Collapsible>

      <Tabs fluid pr="0" pl="0" mb="0" fontSize="16px">
        <Tabs.Tab
          selected={category === 'monitor'}
          icon="heartbeat"
          onClick={() => setCategory('monitor')}
        >
          Squad Monitor
        </Tabs.Tab>
        {!!data.orbital_cannon && (
          <Tabs.Tab
            selected={category === 'ob'}
            icon="crosshairs"
            onClick={() => setCategory('ob')}
          >
            Orbital Bombardment
          </Tabs.Tab>
        )}
      </Tabs>
      {category === 'monitor' && <SquadMonitor />}
      {category === 'ob' && data.orbital_cannon && <OrbitalBombardment />}
    </>
  );
};

const SquadMonitor = (props) => {
  const { act, data } = useBackend();

  const sortByRole = (a, b) => {
    a = a.role;
    b = b.role;
    const roleValues = {
      'Squad Leader': 10,
      'Squad Smartgunner': 9,
      'Squad Corpsman': 6,
      'Squad Engineer': 5,
      'Squad Marine': 4,
    };
  };

  let { marines, squad_leader } = data;

  const [hidden_marines, setHiddenMarines] = useLocalState(
    'hidden_marines',
    [],
  );

  const [showHiddenMarines, setShowHiddenMarines] = useLocalState(
    'showhidden',
    false,
  );
  const [showDeadMarines, setShowDeadMarines] = useLocalState(
    'showdead',
    false,
  );

  const [marineSearch, setMarineSearch] = useLocalState('marinesearch', null);

  let determine_status_color = (status) => {
    let conscious = status.includes('Conscious');
    let unconscious = status.includes('Unconscious');

    let state_color = 'red';
    if (conscious) {
      state_color = 'green';
    } else if (unconscious) {
      state_color = 'yellow';
    }
    return state_color;
  };

  let toggle_marine_hidden = (ref) => {
    if (!hidden_marines.includes(ref)) {
      setHiddenMarines([...hidden_marines, ref]);
    } else {
      let array_copy = [...hidden_marines];
      let index = array_copy.indexOf(ref);
      if (index > -1) {
        array_copy.splice(index, 1);
      }
      setHiddenMarines(array_copy);
    }
  };

  let location_filter;
  if (data.z_hidden === 2) {
    location_filter = 'groundside';
  } else if (data.z_hidden === 1) {
    location_filter = 'shipside';
  } else {
    location_filter = 'all';
  }

  return (
    <Section
      fontSize="14px"
      title="Monitor"
      buttons={
        <>
          <Button
            color="yellow"
            tooltip="Show marines depending on location"
            onClick={() => act('choose_z')}
          >
            Shown: {location_filter}
          </Button>
          {(showDeadMarines && (
            <Button color="yellow" onClick={() => setShowDeadMarines(false)}>
              Hide dead
            </Button>
          )) || (
            <Button color="yellow" onClick={() => setShowDeadMarines(true)}>
              Show dead
            </Button>
          )}
          {(showHiddenMarines && (
            <Button color="yellow" onClick={() => setShowHiddenMarines(false)}>
              Hide hidden
            </Button>
          )) || (
            <Button color="yellow" onClick={() => setShowHiddenMarines(true)}>
              Show hidden
            </Button>
          )}
          <Button
            color="yellow"
            icon="arrow-right"
            onClick={() => act('squad_transfer')}
          >
            Transfer Marine
          </Button>
          <Button
            color="red"
            icon="running"
            onClick={() => act('insubordination')}
          >
            Insubordination
          </Button>
        </>
      }
    >
      <Input
        fluid
        placeholder="Search.."
        mb="4px"
        value={marineSearch}
        onInput={(e, value) => setMarineSearch(value)}
      />
      <Table>
        <Table.Row bold fontSize="14px">
          <Table.Cell textAlign="center">Name</Table.Cell>
          <Table.Cell textAlign="center">Role</Table.Cell>
          <Table.Cell textAlign="center" collapsing>
            State
          </Table.Cell>
          <Table.Cell textAlign="center">Location</Table.Cell>
          <Table.Cell textAlign="center" collapsing fontSize="12px">
            SL Dist.
          </Table.Cell>
          <Table.Cell textAlign="center" />
        </Table.Row>
        {squad_leader && (
          <Table.Row key="index" bold>
            <Table.Cell collapsing p="2px">
              <Button
                onClick={() => act('use_cam', { cam_target: squad_leader.ref })}
              >
                {squad_leader.name}
              </Button>
            </Table.Cell>
            <Table.Cell p="2px">{squad_leader.role}</Table.Cell>
            <Table.Cell
              p="2px"
              color={determine_status_color(squad_leader.state)}
            >
              {squad_leader.state}
            </Table.Cell>
            <Table.Cell p="2px">{squad_leader.area_name}</Table.Cell>
            <Table.Cell p="2px" collapsing>
              {squad_leader.distance}
            </Table.Cell>
            <Table.Cell />
          </Table.Row>
        )}
        {marines &&
          marines
            .sort(sortByRole)
            .filter((marine) => {
              if (marineSearch) {
                const searchableString = String(marine.name).toLowerCase();
                return searchableString.match(new RegExp(marineSearch, 'i'));
              }
              return marine;
            })
            .map((marine, index) => {
              if (squad_leader) {
                if (marine.ref === squad_leader.ref) {
                  return;
                }
              }
              if (hidden_marines.includes(marine.ref) && !showHiddenMarines) {
                return;
              }
              if (marine.state === 'Dead' && !showDeadMarines) {
                return;
              }

              return (
                <Table.Row key={index}>
                  <Table.Cell collapsing p="2px">
                    <Button
                      onClick={() => act('use_cam', { cam_target: marine.ref })}
                    >
                      {marine.name}
                    </Button>
                  </Table.Cell>
                  <Table.Cell p="2px">{marine.role}</Table.Cell>
                  <Table.Cell
                    p="2px"
                    color={determine_status_color(marine.state)}
                  >
                    {marine.state}
                  </Table.Cell>
                  <Table.Cell p="2px">{marine.area_name}</Table.Cell>
                  <Table.Cell p="2px" collapsing>
                    {marine.distance}
                  </Table.Cell>
                  <Table.Cell p="2px">
                    {(hidden_marines.includes(marine.ref) && (
                      <Button
                        icon="plus"
                        color="green"
                        tooltip="Show marine"
                        onClick={() => toggle_marine_hidden(marine.ref)}
                      />
                    )) || (
                      <Button
                        icon="minus"
                        color="red"
                        tooltip="Hide marine"
                        onClick={() => toggle_marine_hidden(marine.ref)}
                      />
                    )}
                    <Button
                      icon="arrow-up"
                      color="green"
                      tooltip="Promote marine to Squad Leader"
                      onClick={() =>
                        act('replace_lead', { target: marine.ref })
                      }
                    />
                  </Table.Cell>
                </Table.Row>
              );
            })}
      </Table>
    </Section>
  );
};

const MainDashboard = (props) => {
  const { act, data } = useBackend();

  let { current_squad, active_primary_objective, active_secondary_objective } =
    data;

  return (
    <Section
      fontSize="16px"
      title={current_squad + ' Overwatch | Dashboard'}
      buttons={
        <>
          <Button icon="user" onClick={() => act('change_operator')}>
            Operator - {data.operator}
          </Button>
          <Button icon="sign-out-alt" onClick={() => act('logout')}>
            Stop Overwatch
          </Button>
        </>
      }
    >
      <Table fill mb="5px">
        <Table.Row bold>
          <Table.Cell textAlign="center">PRIMARY ORDERS</Table.Cell>
          <Table.Cell textAlign="center">SECONDARY ORDERS</Table.Cell>
        </Table.Row>
        <Table.Row>
          <Table.Cell textAlign="center">
            {active_primary_objective ? active_primary_objective : 'NONE'}
          </Table.Cell>
          <Table.Cell textAlign="center">
            {active_secondary_objective ? active_secondary_objective : 'NONE'}
          </Table.Cell>
        </Table.Row>
      </Table>
      <Box textAlign="center">
        <Button
          inline
          width="23%"
          icon="envelope"
          onClick={() => act('set_primary')}
        >
          SET PRIMARY
        </Button>
        <Button
          inline
          width="23%"
          icon="envelope"
          onClick={() => act('set_secondary')}
        >
          SET SECONDARY
        </Button>
      </Box>

      <Box textAlign="center">
        <Button
          inline
          width="45%"
          icon="envelope"
          onClick={() => act('message')}
        >
          MESSAGE SQUAD
        </Button>
        <Button
          inline
          width="45%"
          icon="person"
          onClick={() => act('sl_message')}
        >
          MESSAGE SQUAD LEADER
        </Button>
      </Box>
    </Section>
  );
};
const RoleTable = (props) => {
  const { act, data } = useBackend();

  const {
    squad_leader,
    smart_alive,
    smart_count,
    medic_count,
    medic_alive,
    engi_alive,
    engi_count,
    living_count,
    total_deployed,
  } = data;

  return (
    <Table m="1px" fontSize="12px" bold>
      <Table.Row>
        <Table.Cell textAlign="center" p="4px">
          Squad Leader
        </Table.Cell>
        <Table.Cell collapsing p="4px">
          Squad Smartgunners
        </Table.Cell>
        <Table.Cell collapsing p="4px">
          Squad Corpsmen
        </Table.Cell>
        <Table.Cell collapsing p="4px">
          Squad Engineers
        </Table.Cell>
        <Table.Cell collapsing p="4px">
          Total/Living
        </Table.Cell>
      </Table.Row>
      <Table.Row>
        {(squad_leader && (
          <Table.Cell textAlign="center">
            {squad_leader.name ? squad_leader.name : 'NONE'}
            <Box color={squad_leader.state !== 'Dead' ? 'green' : 'red'}>
              {squad_leader.state !== 'Dead' ? 'ALIVE' : 'DEAD'}
            </Box>
          </Table.Cell>
        )) || (
          <Table.Cell textAlign="center">
            NONE
            <Box color="red">NOT DEPLOYED</Box>
          </Table.Cell>
        )}
        <Table.Cell textAlign="center" bold>
          <Box>{smart_count ? smart_count + ' DEPLOYED' : 'NONE'}</Box>
          <Box color={smart_alive ? 'green' : 'red'}>
            {smart_count
              ? smart_alive
                ? smart_alive + ' ALIVE'
                : 'DEAD'
              : 'N/A'}
          </Box>
        </Table.Cell>
        <Table.Cell textAlign="center" bold>
          <Box>{medic_count} DEPLOYED</Box>
          <Box color={medic_alive ? 'green' : 'red'}>{medic_alive} ALIVE</Box>
        </Table.Cell>
        <Table.Cell textAlign="center" bold>
          <Box>{engi_count} DEPLOYED</Box>
          <Box color={engi_alive ? 'green' : 'red'}>{engi_alive} ALIVE</Box>
        </Table.Cell>
        <Table.Cell textAlign="center" bold>
          <Box>{total_deployed} TOTAL</Box>
          <Box color={living_count ? 'green' : 'red'}>{living_count} ALIVE</Box>
        </Table.Cell>
      </Table.Row>
    </Table>
  );
};

const OrbitalBombardment = (props) => {
  const { act, data } = useBackend();

  let ob_status = 'READY TO FIRE';
  let ob_color = 'green';
  if (!data.orbital_ammunition) {
    ob_status = 'UNAVAILABLE: NOT CHAMBERED';
    ob_color = 'none';
  }

  return (
    <Section
      fontSize="14px"
      title="Orbital Bombardment"
      buttons={
        <Button
          fontSize="14px"
          icon="crosshairs"
          color={ob_color}
          onClick={() => act('dropbomb')}
          bold
        >
          {ob_status}
        </Button>
      }
    >
      <Stack vertical>
        <Stack.Item fontSize="14px">
          <LabeledControls>
            {data.orbital_targets ? <OrbitalTargets /> : null}
          </LabeledControls>
        </Stack.Item>
        <Stack.Item />
      </Stack>
    </Section>
  );
};

const OrbitalTargets = (props) => {
  const { act, data } = useBackend();

  return (
    <Stack>
      {data.orbital_targets.map((orbital_laser, index) => {
        return (
          <Stack.Item key={index}>
            <Button
              onClick={() =>
                act(
                  'change_orbital_target',
                  {
                    target: orbital_laser.ref,
                  },
                  'use_cam',
                  {
                    cam_target: orbital_laser.ref,
                  },
                )
              }
            >
              {orbital_laser.name}
            </Button>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};
