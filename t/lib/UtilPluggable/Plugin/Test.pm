package UtilPluggable::Plugin::Test;

sub utils {
  return
    {
     -pluggable => [
                    [
                     'UtilPluggable', '', # dummy,
                     {
                      "test" => sub {sub (){ return "test\n"}}
                     }
                    ]
                   ],
    }
}

1;


