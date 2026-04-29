defmodule TullnData.Hora.GmlHandlerTest do
  use ExUnit.Case, async: true

  alias TullnData.Hora.GmlHandler

  @sample_gml """
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:FeatureCollection xmlns:gml="http://www.opengis.net/gml/3.2"
    xmlns:nz-core="http://inspire.ec.europa.eu/schemas/nz-core/4.0"
    xmlns:base="http://inspire.ec.europa.eu/schemas/base/3.3"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <gml:featureMember>
      <nz-core:HazardArea gml:id="id-tulln-1">
        <nz-core:beginLifeSpanVersion>2020-03-21T00:00:00+01:00</nz-core:beginLifeSpanVersion>
        <nz-core:determinationMethod>modelling</nz-core:determinationMethod>
        <nz-core:inspireId>
          <base:Identifier>
            <base:localId>32101_0</base:localId>
            <base:namespace>https://data.inspire.gv.at/test</base:namespace>
          </base:Identifier>
        </nz-core:inspireId>
        <nz-core:geometry>
          <gml:Surface srsName="urn:ogc:def:crs:EPSG::4326">
            <gml:patches>
              <gml:PolygonPatch>
                <gml:exterior>
                  <gml:LinearRing>
                    <gml:posList>48.33 15.88 48.34 15.88 48.34 15.90 48.33 15.90 48.33 15.88</gml:posList>
                  </gml:LinearRing>
                </gml:exterior>
              </gml:PolygonPatch>
            </gml:patches>
          </gml:Surface>
        </nz-core:geometry>
        <nz-core:likelihoodOfOccurrence>
          <nz-core:LikelihoodOfOccurrence>
            <nz-core:quantitativeLikelihood>
              <nz-core:QuantitativeLikelihood>
                <nz-core:returnPeriod>30</nz-core:returnPeriod>
              </nz-core:QuantitativeLikelihood>
            </nz-core:quantitativeLikelihood>
          </nz-core:LikelihoodOfOccurrence>
        </nz-core:likelihoodOfOccurrence>
      </nz-core:HazardArea>
    </gml:featureMember>
    <gml:featureMember>
      <nz-core:HazardArea gml:id="id-other-1">
        <nz-core:beginLifeSpanVersion>2020-03-21T00:00:00+01:00</nz-core:beginLifeSpanVersion>
        <nz-core:determinationMethod>modelling</nz-core:determinationMethod>
        <nz-core:inspireId>
          <base:Identifier>
            <base:localId>10101_0</base:localId>
            <base:namespace>https://data.inspire.gv.at/test</base:namespace>
          </base:Identifier>
        </nz-core:inspireId>
        <nz-core:geometry>
          <gml:Surface srsName="urn:ogc:def:crs:EPSG::4326">
            <gml:patches>
              <gml:PolygonPatch>
                <gml:exterior>
                  <gml:LinearRing>
                    <gml:posList>47.80 16.50 47.81 16.50 47.81 16.52 47.80 16.52 47.80 16.50</gml:posList>
                  </gml:LinearRing>
                </gml:exterior>
              </gml:PolygonPatch>
            </gml:patches>
          </gml:Surface>
        </nz-core:geometry>
        <nz-core:likelihoodOfOccurrence>
          <nz-core:LikelihoodOfOccurrence>
            <nz-core:quantitativeLikelihood>
              <nz-core:QuantitativeLikelihood>
                <nz-core:returnPeriod>30</nz-core:returnPeriod>
              </nz-core:QuantitativeLikelihood>
            </nz-core:quantitativeLikelihood>
          </nz-core:LikelihoodOfOccurrence>
        </nz-core:likelihoodOfOccurrence>
      </nz-core:HazardArea>
    </gml:featureMember>
    <gml:featureMember>
      <nz-core:HazardArea gml:id="id-tulln-2">
        <nz-core:beginLifeSpanVersion>2020-03-21T00:00:00+01:00</nz-core:beginLifeSpanVersion>
        <nz-core:determinationMethod>modelling</nz-core:determinationMethod>
        <nz-core:inspireId>
          <base:Identifier>
            <base:localId>32131_5</base:localId>
            <base:namespace>https://data.inspire.gv.at/test</base:namespace>
          </base:Identifier>
        </nz-core:inspireId>
        <nz-core:geometry>
          <gml:Surface srsName="urn:ogc:def:crs:EPSG::4326">
            <gml:patches>
              <gml:PolygonPatch>
                <gml:exterior>
                  <gml:LinearRing>
                    <gml:posList>48.30 15.92 48.31 15.92 48.31 15.94 48.30 15.94 48.30 15.92</gml:posList>
                  </gml:LinearRing>
                </gml:exterior>
              </gml:PolygonPatch>
            </gml:patches>
          </gml:Surface>
        </nz-core:geometry>
        <nz-core:likelihoodOfOccurrence>
          <nz-core:LikelihoodOfOccurrence>
            <nz-core:quantitativeLikelihood>
              <nz-core:QuantitativeLikelihood>
                <nz-core:returnPeriod>30</nz-core:returnPeriod>
              </nz-core:QuantitativeLikelihood>
            </nz-core:quantitativeLikelihood>
          </nz-core:LikelihoodOfOccurrence>
        </nz-core:likelihoodOfOccurrence>
      </nz-core:HazardArea>
    </gml:featureMember>
  </gml:FeatureCollection>
  """

  setup do
    path = Path.join(System.tmp_dir!(), "test_hora_#{System.unique_integer([:positive])}.gml")
    File.write!(path, @sample_gml)
    on_exit(fn -> File.rm(path) end)
    %{gml_path: path}
  end

  test "extracts only Bezirk Tulln features (prefix 321)", %{gml_path: gml_path} do
    state = GmlHandler.initial_state("321", 30)

    {:ok, final_state, _rest} =
      :xmerl_sax_parser.file(
        String.to_charlist(gml_path),
        event_fun: &GmlHandler.handle_event/3,
        event_state: state
      )

    features = GmlHandler.features(final_state)

    assert length(features) == 2
    assert Enum.map(features, & &1.source_id) == ["32101_0", "32131_5"]
  end

  test "parses polygon coordinates as {lon, lat} tuples", %{gml_path: gml_path} do
    state = GmlHandler.initial_state("321", 30)

    {:ok, final_state, _rest} =
      :xmerl_sax_parser.file(
        String.to_charlist(gml_path),
        event_fun: &GmlHandler.handle_event/3,
        event_state: state
      )

    [feature | _] = GmlHandler.features(final_state)
    %Geo.Polygon{coordinates: [ring], srid: 4326} = feature.geom

    assert hd(ring) == {15.88, 48.33}
    assert List.last(ring) == {15.88, 48.33}
    assert length(ring) == 5
  end

  test "parses source_updated_at from beginLifeSpanVersion", %{gml_path: gml_path} do
    state = GmlHandler.initial_state("321", 30)

    {:ok, final_state, _rest} =
      :xmerl_sax_parser.file(
        String.to_charlist(gml_path),
        event_fun: &GmlHandler.handle_event/3,
        event_state: state
      )

    [feature | _] = GmlHandler.features(final_state)
    assert %DateTime{year: 2020, month: 3, day: 20} = feature.source_updated_at
  end

  test "excludes features outside Bezirk Tulln", %{gml_path: gml_path} do
    state = GmlHandler.initial_state("101", 30)

    {:ok, final_state, _rest} =
      :xmerl_sax_parser.file(
        String.to_charlist(gml_path),
        event_fun: &GmlHandler.handle_event/3,
        event_state: state
      )

    features = GmlHandler.features(final_state)
    assert length(features) == 1
    assert hd(features).source_id == "10101_0"
  end
end
