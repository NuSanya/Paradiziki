import { useState } from 'react';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NanoMap,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

type SatelliteControlData = {
  tabIndex: number;
  satellites: Satellite[];
  notice: string;
  notice_color: string;
  has_goal: boolean;
  coverage: number;
  coverage_goal: number;
  max_meteor: number;
  testing: boolean;
  thrown: number;
  zoom: number;
  offsetX: number;
  offsetY: number;
  defended: Meteor[];
  collisions: Meteor[];
  fake_meteors: Meteor[];
  stationLevelNum: number[];
  stationLevelName: string[];
};

type Satellite = {
  id: string;
  mode: string;
  active: boolean;
  x: number;
  y: number;
  z: number;
};

type Meteor = {
  x: number;
  y: number;
  z: number;
};

export const SatelliteControl = (props: unknown) => {
  const { act, data } = useBackend<SatelliteControlData>();
  const [tabIndex, setTabIndex] = useState(data.tabIndex);

  const handleTabChange = (index: number) => {
    setTabIndex(index);
    act('set_tab_index', { tab_index: index });
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
        <Stack fill vertical fillPositionedParent>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                icon="table"
                selected={tabIndex === 0}
                onClick={() => handleTabChange(0)}
              >
                Спутники
              </Tabs.Tab>
              <Tabs.Tab
                icon="map-marked-alt"
                selected={tabIndex === 1}
                onClick={() => handleTabChange(1)}
              >
                Просмотр карты
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow={1} overflow="hidden">
            {decideTab(tabIndex)}
          </Stack.Item>
          <Stack.Item>
            <SatelliteControlFooter />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SatelliteControlSatellitesList = (props: unknown) => {
  const { act, data } = useBackend<SatelliteControlData>();
  const { satellites } = data;

  return (
    <Section title="Управление спутниковой сетью" fill overflow="auto">
      <LabeledList>
        {satellites.map((sat) => (
          <LabeledList.Item key={sat.id} label={`#${sat.id}`}>
            <Box inline bold color={sat.active ? 'good' : 'average'} mr={2}>
              {sat.mode}
            </Box>
            <Button
              icon={sat.active ? 'power-off' : 'times'}
              color={sat.active ? 'average' : 'good'}
              onClick={() => act('toggle', { id: sat.id.toString() })}
            >
              {sat.active ? 'Деактивировать' : 'Активировать'}
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
    offsetX = 0,
    offsetY = 0,
    stationLevelNum,
    stationLevelName,
  } = data;
  const [z_current, setZCurrent] = useState(stationLevelNum[0]);
  const [zoom, setZoom] = useState(1);
  return (
    <Box maxHeight="100%" style={{ display: 'flex' }}>
      <NanoMap
        onZoom={(v, n) => setZoom(n)}
        offsetX={offsetX}
        offsetY={offsetY}
        zNames={stationLevelName}
        zLevels={stationLevelNum}
        zCurrent={z_current}
        setZCurrent={setZCurrent}
        onOffsetChangeEnded={(e, state) =>
          act('set_offset', {
            offset_x: state.x,
            offset_y: state.y,
          })
        }
      >
        {satellites.map((sat) => (
          <NanoMap.MarkerIcon
            key={`sat_${sat.id}`}
            x={sat.x}
            y={sat.y}
            z={sat.z}
            z_current={z_current}
            zoom={zoom}
            icon="satellite"
            tooltip={sat.active ? 'Спутник щита' : 'Неактивный спутник'}
            tooltipPosition="auto"
            color={sat.active ? 'white' : 'grey'}
            onClick={() => act('toggle', { id: sat.id })}
          />
        ))}

        {has_goal &&
          defended.map((meteor, i) => (
            <NanoMap.MarkerIcon
              key={`defended_${i}_${meteor.x}_${meteor.y}`}
              x={meteor.x}
              y={meteor.y}
              z={meteor.z}
              z_current={z_current}
              zoom={zoom}
              icon="shield"
              tooltip="Успешная защита"
              tooltipPosition="auto"
              color="blue"
            />
          ))}

        {has_goal &&
          collisions.map((meteor, i) => (
            <NanoMap.MarkerIcon
              key={`collision_${i}_${meteor.x}_${meteor.y}`}
              x={meteor.x}
              y={meteor.y}
              z={meteor.z}
              z_current={z_current}
              zoom={zoom}
              icon="x"
              tooltip="Столкновение метеора"
              tooltipPosition="auto"
              color="red"
            />
          ))}

        {has_goal &&
          fake_meteors.map((meteor, i) => (
            <NanoMap.MarkerIcon
              key={`meteor_${i}_${meteor.x}_${meteor.y}`}
              x={meteor.x}
              y={meteor.y}
              z={meteor.z}
              z_current={z_current}
              zoom={zoom}
              icon="meteor"
              tooltip="Метеор"
              tooltipPosition="auto"
              color="white"
            />
          ))}
      </NanoMap>
    </Box>
  );
};

const SatelliteControlFooter = (props: unknown) => {
  const { act, data } = useBackend<SatelliteControlData>();
  const {
    notice,
    notice_color,
    has_goal,
    coverage,
    coverage_goal,
    testing,
    max_meteor,
  } = data;

  return (
    <>
      {has_goal && (
        <Stack.Item>
          <Section title="Антиметеоритное покрытие станции">
            <Stack fill>
              <Stack.Item grow>
                <ProgressBar
                  color={coverage >= coverage_goal ? 'good' : 'average'}
                  value={coverage}
                  minValue={0}
                  maxValue={max_meteor}
                >
                  {coverage}%
                </ProgressBar>
              </Stack.Item>
              <Stack.Item>
                <Button disabled={testing} onClick={() => act('begin_test')}>
                  Активировать симуляцию
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      )}
      <Stack.Item
        align="center"
        fontFamily="sans-serif"
        fontSize="14px"
        textColor={notice_color}
      >
        {notice}
      </Stack.Item>
    </>
  );
};
