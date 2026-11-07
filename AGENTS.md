# Development workflow

- Write throwaway and utility scripts in Ruby using the standard library. Keep
  temporary scripts outside the repository root and delete them when finished.
- For changes to business rules, first add tests that distinguish allowed and
  rejected behavior, including boundary values and permission failures.
- Run `bin/mutant` when changing any subject in `config/mutant.yml`. All generated
  mutations must be killed. Fix missing assertions or redundant production code;
  do not lower the threshold, exclude surviving mutations, or disable the gate.
- Add new business-rule methods to the mutation subject list and declare `cover`
  in their tests. Keep database side effects out of pure rule tests where possible.
- `bin/ci` is mandatory before merge or deployment. It includes ordinary tests,
  mutation testing, seed checks, style and security audits. Only a complete green
  run may publish the `signoff` commit status.
- An incremental mutation run is for local feedback only. It never replaces the
  complete configured subject list required by `bin/ci`.
