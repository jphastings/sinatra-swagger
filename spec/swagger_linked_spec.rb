
require "tempfile"

describe Sinatra::Swagger::SwaggerLinked do
  it "must allow registration of a swagger specification" do
    setup_app do
      register Sinatra::Swagger::SwaggerLinked
    end
    expect(app).to respond_to(:swagger).with(1).argument
  end

  it "must load its helpers on registration" do
    mock_app = double
    allow(mock_app).to receive(:helpers)
    described_class.registered(mock_app)
    expect(mock_app).to have_received(:helpers).with(described_class::Helpers)
  end

  context "with no declared swagger spec" do
    before do
      @exec_environ = double
      settings = double('app.settings')
      allow(settings).to receive(:swagger).and_return(nil)
      allow(@exec_environ).to receive(:settings).and_return(settings)
      @exec_environ.extend(described_class::Helpers)
    end

    it "must raise an error when swagger_spec is called" do
      expect { @exec_environ.swagger_spec }.to raise_error
    end

    it "must raise an error when schema_from_spec_at is called" do
      expect { @exec_environ.schema_from_spec_at("/") }.to raise_error
    end
  end

  context "with a declared swagger spec" do
    before do
      @exec_environ = double
      @settings = double('app.settings')
      @swagger = instance_double(Swagger::Base)
      @request_spec = {
        spec: {
          200 => {
            "schema" => { "things" => :what_they_need_to_be }
          }
        }
      }
      allow(@swagger).to receive(:[]).with('definitions').and_return(:extra)
      allow(@swagger).to receive(:request_spec).and_return(@request_spec)
      allow(@settings).to receive(:swagger).and_return(@swagger)
      allow(@exec_environ).to receive(:settings).and_return(@settings)
      @env = :env
      allow(@exec_environ).to receive(:env).and_return(@env)
      @exec_environ.extend(described_class::Helpers)
    end

    it "must return the swagger spec for this request when swagger_spec is called" do
      expect(@exec_environ.swagger_spec).to eq(@request_spec)
      expect(@swagger).to have_received(:request_spec).with(env: @env)
    end

    context "schema_from_spec_at" do
      context "with no schema defined for this route" do
        it "must return nil" do
          expect(@exec_environ.schema_from_spec_at("somewhere")).to be_nil
        end
      end

      context "with a schema defined for this route" do
        it "must return the schema at the requested path" do
          expect(@exec_environ.schema_from_spec_at("200/schema")['things']).to eq(:what_they_need_to_be)
        end

        it "must include root definitions in the schema" do
          expect(@exec_environ.schema_from_spec_at("200/schema")['definitions']).to eq(:extra)
        end
      end
    end
  end
end