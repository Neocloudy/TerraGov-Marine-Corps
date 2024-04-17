import { useBackend, useLocalState, useSharedState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Divider,
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
    <Window width={800} height={600} theme={'crt-green'}>
      <Window.Content>
        {(!data.current_squad && <HomePanel />) || <SquadPanel />}
      </Window.Content>
    </Window>
  );
};

const HomePanel = (props) => {
  const { act, data } = useBackend();

  // Buttons don't seem to support hexcode colors, so we'll have to do this manually, sadly
  const squadColorMap = {
    alpha: 'red',
    bravo: 'yellow',
    charlie: 'purple',
    delta: 'blue',
  };

  return (
    <Section
      fontSize="20px"
      textAlign="center"
      title="OVERWATCH DISABLED - SELECT SQUAD"
    >
      <Stack justify="center" align="end" fontSize="20px">
        {data.squad_list.map((squad, index) => {
          return (
            <Stack.Item key={index}>
              <Button
                color={
                  squadColorMap[squad.toLowerCase()]
                    ? squadColorMap[squad.toLowerCase()]
                    : 'lime'
                }
                onClick={() => act('pick_squad', { squad: squad })}
              >
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
        {!!data.can_launch_crates && (
          <Tabs.Tab
            selected={category === 'supply'}
            icon="wrench"
            onClick={() => setCategory('supply')}
          >
            Supply Drop
          </Tabs.Tab>
        )}
        {!!data.can_launch_obs && (
          <Tabs.Tab
            selected={category === 'ob'}
            icon="bomb"
            onClick={() => setCategory('ob')}
          >
            Orbital Bombardment
          </Tabs.Tab>
        )}
        <Tabs.Tab icon="map" onClick={() => act('tacmap_unpin')}>
          Tactical Map
        </Tabs.Tab>
      </Tabs>
      {category === 'monitor' && <SquadMonitor />}
      {category === 'ob' && data.can_launch_obs && <OrbitalBombardment />}
    </>
  );
};

const MainDashboard = (props) => {
  const { act, data } = useBackend();

  let { current_squad, primary_objective, secondary_objective } = data;

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
            {primary_objective ? primary_objective : 'NONE'}
          </Table.Cell>
          <Table.Cell textAlign="center">
            {secondary_objective ? secondary_objective : 'NONE'}
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
        {primary_objective && (
          <Button
            inline
            width="23%"
            icon="person"
            onClick={() => act('remind_primary')}
          >
            REMIND PRIMARY
          </Button>
        )}
        <Button
          inline
          width="23%"
          icon="envelope"
          onClick={() => act('set_secondary')}
        >
          SET SECONDARY
        </Button>
        {secondary_objective && (
          <Button
            inline
            width="23%"
            icon="person"
            onClick={() => act('remind_secondary')}
          >
            REMIND SECONDARY
          </Button>
        )}
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
    leaders_alive,
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
          Smartgunner
        </Table.Cell>
        <Table.Cell collapsing p="4px">
          Hospital Corpsmen
        </Table.Cell>
        <Table.Cell collapsing p="4px">
          Combat Technicians
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
          <Box color={smart_count ? 'green' : 'red'}>
            {smart_count ? smart_count + ' DEPLOYED' : 'NONE'}
          </Box>
          <Box color={smart_alive ? 'green' : 'red'}>
            {smart_count ? (smart_alive ? 'ALIVE' : 'DEAD') : 'N/A'}
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

const SquadMonitor = (props) => {
  const { act, data } = useBackend();

  const sortByRole = (a, b) => {
    a = a.role;
    b = b.role;
    const roleValues = {
      'Squad Leader': 10,
      Smartgunner: 9,
      'Hospital Corpsman': 6,
      'Combat Technician': 5,
      Rifleman: 4,
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
            onClick={() => act('change_locations_ignored')}
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
            onClick={() => act('transfer_marine')}
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
              {(squad_leader.has_helmet && (
                <Button
                  onClick={() =>
                    act('use_cam', { target_ref: squad_leader.ref })
                  }
                >
                  {squad_leader.name}
                </Button>
              )) || <Box color="yellow">{squad_leader.name} (NO HELMET)</Box>}
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
                    {(marine.has_helmet && (
                      <Button
                        onClick={() =>
                          act('use_cam', { target_ref: marine.ref })
                        }
                      >
                        {marine.name}
                      </Button>
                    )) || <Box color="yellow">{marine.name} (NO HELMET)</Box>}
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
                      onClick={() => act('replace_lead', { ref: marine.ref })}
                    />
                  </Table.Cell>
                </Table.Row>
              );
            })}
      </Table>
    </Section>
  );
};

const OrbitalBombardment = (props) => {
  const { act, data } = useBackend();

  const [OBX, setOBX] = useSharedState('obx', 0);
  const [OBY, setOBY] = useSharedState('oby', 0);

  let ob_status = 'Ready';
  let ob_color = 'green';
  if (data.ob_cooldown) {
    ob_status = 'Cooldown - ' + data.ob_cooldown / 10 + ' seconds';
    ob_color = 'yellow';
  } else if (!data.ob_loaded) {
    ob_status = 'Not chambered';
    ob_color = 'red';
  }

  return (
    <Section fontSize="14px" title="Orbital Bombardment">
      <Stack justify={'space-between'} m="10px">
        <Stack.Item fontSize="14px">
          <LabeledControls mb="5px">
            <LabeledControls.Item label="STATUS">
              <Box color={ob_color} bold>
                {ob_status}
              </Box>
            </LabeledControls.Item>
          </LabeledControls>
          <Box textAlign="center">
            <Button
              fontSize="20px"
              width="100%"
              icon="bomb"
              color="red"
              onClick={() => act('dropbomb')}
            >
              Fire
            </Button>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Divider vertical />
        </Stack.Item>
        <SavedCoordinates forOB />
      </Stack>
    </Section>
  );
};

const SavedCoordinates = (props) => {
  const { act, data } = useBackend();

  const [OBX, setOBX] = useSharedState('obx', 0);
  const [OBY, setOBY] = useSharedState('oby', 0);
  const [supplyX, setSupplyX] = useSharedState('supplyx', 0);
  const [supplyY, setSupplyY] = useSharedState('supply', 0);

  const { forOB, forSupply } = props;

  let transferCoords = (x, y) => {
    if (forSupply) {
      setSupplyX(x);
      setSupplyY(y);
    } else if (forOB) {
      setOBX(x);
      setOBY(y);
    }
  };

  console.log(props);

  return (
    <Stack.Item>
      <Box bold textAlign="center">
        Max 3 stored coordinates. Will overwrite oldest first.
      </Box>
      <Table>
        <Table.Row bold>
          <Table.Cell p="5px" collapsing>
            LONG.
          </Table.Cell>
          <Table.Cell p="5px" collapsing>
            LAT.
          </Table.Cell>
          <Table.Cell p="5px">COMMENT</Table.Cell>
          <Table.Cell p="5px" collapsing />
        </Table.Row>
        {data.saved_coordinates.map((coords, index) => (
          <Table.Row key={index}>
            <Table.Cell p="6px">{coords.x}</Table.Cell>
            <Table.Cell p="5px">{coords.y}</Table.Cell>
            <Table.Cell p="5px">
              <Input
                width="100%"
                value={coords.comment}
                onChange={(e, value) =>
                  act('change_coordinate_comment', {
                    comment: value,
                    index: coords.index,
                  })
                }
              />
            </Table.Cell>
            <Table.Cell p="5px">
              <Button
                color="yellow"
                icon="arrow-left"
                onClick={() => transferCoords(coords.x, coords.y)}
              />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Stack.Item>
  );
};
