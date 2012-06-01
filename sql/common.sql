create type integerIdentifier
    int not null
    default autoincrement
;


grant connect to person;


create or replace procedure person.by_department (
    @id integerIdentifier,
    @at date default today()
) begin

    select *
        from dbo.person join emp rel ...
    where exists ( select * from
            dbo.emp_dept_tree edt
            where edt.parent_id = @id
                and edt.dept_id = dbo.person.person_id
        )

end;