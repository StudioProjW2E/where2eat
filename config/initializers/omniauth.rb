OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
	OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

	if Rails.env.production?
		 # public, production
		 provider :facebook, '1534922070141089', '91efc2cefdf2aa1a660b38cca0f55805', {:client_options => {:ssl => {:ca_file => Rails.root.join("cacert.pem").to_s}}}
	else
		 # testing, localhost
		 provider :facebook, '1535220650111231', '8c513e6c88e3f1a9ba11e649e78e87d6', {:client_options => {:ssl => {:ca_file => Rails.root.join("cacert.pem").to_s}}}
	end
 end