import { useState } from 'react';
import { useBackend } from '../backend';
import { Box, Button, LabeledList, NanoMap, ProgressBar, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';

type SatelliteControlData = {
  tabIndex: number;
  satellites: Satellite[];
  notice: string;
  notice_color: string;
  has_goal: boolean;
  coverage: number;
  coverage_goal: number;
  testing: boolean;
  thrown: number;
  zoom: number;
  offsetX: number;
  offsetY: number;
  defended: Meteor[];
  collisions: Meteor[];
  fake_meteors: Meteor[];
};

type Satellite = {
  id: string;
  mode: string;
  active: boolean;
  x: number;
  y: number;
};

type Meteor = {
  x: number;
  y: number;
};

export const SatelliteControl = (props: unknown) => {
  const { act, data } = useBackend<SatelliteControlData>();
  const [tabIndex, setTabIndex] = useState(data.tabIndex);

  const handleTabChange = (index: number) => {
    setTabIndex(index);
    act('set_tab_index', { tab_index: index + 1 });
  };

  const decideTab = (index: number) => {
    switch (index) {
      case 0:
        return <SatelliteControlSatellitesList />;
      case 1:
        return <SatelliteControlMapView />;
      default:
        return "WE SHOULDN'T BE HERE!";
    }
  };

  return (
    <Window width={800} height={600}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={tabIndex === 0}
                onClick={() => handleTabChange(0)}>
                Satellites
              </Tabs.Tab>
              <Tabs.Tab
                selected={tabIndex === 1}
                onClick={() => handleTabChange(1)}>
                Map View
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          <Stack.Item grow={1} basis={0}>
            {decideTab(tabIndex)}
          </Stack.Item>

          <SatelliteControlFooter />
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SatelliteControlSatellitesList = (props: unknown) => {
  const { act, data } = useBackend<SatelliteControlData>();
  const { satellites } = data;

  return (
    <Section title="Satellite Network Control">
      <LabeledList>
        {satellites.map((sat) => (
          <LabeledList.Item key={sat.id} label={'#' + sat.id}>
            {sat.mode}{' '}
            <Button
              icon="arrow-circle-right"
              onClick={() => act('toggle', { id: sat.id })}>
              {sat.active ? 'Deactivate' : 'Activate'}
            </Button>
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
};

const SatelliteControlMapView = (props: unknown) => {
  const { act, data } = useBackend<SatelliteControlData>();
  const {
    satellites = [],
    has_goal = false,
    defended = [],
    collisions = [],
    fake_meteors = [],
    zoom = 1,
    offsetX = 0,
    offsetY = 0,
  } = data;

  const safeZoom = Math.max(1, Number(zoom) || 1);
  const safeOffsetX = Number(offsetX) || 0;
  const safeOffsetY = Number(offsetY) || 0;

  return (
    <Box height="100%" mb="0.5rem" overflow="hidden">
      <NanoMap
        zoom={safeZoom}
        offsetX={safeOffsetX}
        offsetY={safeOffsetY}
        onZoom={(_e: unknown, value: number) => act('set_zoom', { zoom: value })}
        onOffsetChange={(_e: unknown, v: { x: number; y: number }) =>
          act('set_offset', {
            offset_x: v.x,
            offset_y: v.y,
          })
       }>
        {satellites.map((sat) => (
          <NanoMap.MarkerIcon
            key={`sat_${sat.id}`}
            x={sat.x}
            y={sat.y}
            icon="satellite"
            tooltip={sat.active ? 'Shield Satellite' : 'Inactive Shield Satellite'}
            color={sat.active ? 'white' : 'grey'}
            onClick={() => act('toggle', { id: sat.id })}
          />
        ))}
        {(has_goal && defended?.length > 0) && defended.map((meteor, i) => (
          <NanoMap.MarkerIcon
            key={`defended_${i}_${meteor.x}_${meteor.y}`}
            x={meteor.x}
            y={meteor.y}
            icon="circle"
            tooltip="Successful Defense"
            color="blue"
          />
        ))}
        {(has_goal && Array.isArray(collisions)) && collisions.map((meteor, i) => (
          <NanoMap.MarkerIcon
            key={`collision_${i}_${meteor.x}_${meteor.y}`}
            x={meteor.x}
            y={meteor.y}
            icon="x"
            tooltip="Meteor Hit"
            color="red"
          />
        ))}
        {(has_goal && fake_meteors?.length > 0) && fake_meteors.map((meteor, i) => (
          <NanoMap.MarkerIcon
            key={`meteor_${i}_${meteor.x}_${meteor.y}`}
            x={meteor.x}
            y={meteor.y}
            icon="meteor"
            tooltip="Incoming Meteor"
            color="white"
          />
        ))}
      </NanoMap>
    </Box>
  );
};

const SatelliteControlFooter = (props: unknown) => {
  const { act, data } = useBackend<SatelliteControlData>();
  const { notice, notice_color, has_goal, coverage, coverage_goal, testing } = data;

  return (
    <>
      {has_goal && (
        <Stack.Item>
          <Section title="Station Shield Coverage">
            <Stack fill>
              <Stack.Item grow>
                <ProgressBar
                  color={coverage >= coverage_goal ? 'good' : 'average'}
                  value={coverage}
                  maxValue={100}>
                  {coverage}%
                </ProgressBar>
              </Stack.Item>
              <Stack.Item>
                <Button
                  disabled={testing}
                  onClick={() => act('begin_test')}>
                  Check coverage
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      )}
      <Stack.Item textColor={notice_color}>
        {notice}
      </Stack.Item>
    </>
  );
};
