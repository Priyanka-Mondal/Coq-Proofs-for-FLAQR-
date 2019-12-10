Set Warnings "-notation-overridden,-parsing". 
Require Import maps.
Require Import smallstep2.
Require Import typerevise.

Module STLC.

Inductive ty : Type :=
  | TBool : ty
  | TArrow : ty -> ty -> ty.  (* Functy *)

Inductive tm : Type :=
  | tvar : string -> tm
  | tapp : tm -> tm -> tm
  | tabs : string -> ty -> tm -> tm
  | ttrue : tm
  | tfalse : tm
  | tif : tm -> tm -> tm -> tm.

Open Scope string_scope.
Definition x := "x".
Definition y := "y".
Definition z := "z".
Hint Unfold x.
Hint Unfold y.
Hint Unfold z.

Notation idB :=
  (tabs x TBool (tvar x)).
Notation idBB :=
  (tabs x (TArrow TBool TBool) (tvar x)).
Notation idBBBB :=
  (tabs x (TArrow (TArrow TBool TBool)
                      (TArrow TBool TBool))(tvar x)).
Notation k := (tabs x TBool (tabs y TBool (tvar x))).
Notation notB := (tabs x TBool (tif (tvar x) tfalse ttrue)).

Inductive value : tm -> Prop :=
  | v_abs : forall x T t,
      value (tabs x T t)
  | v_true :
      value ttrue
  | v_false :
      value tfalse.
Hint Constructors value.

Reserved Notation "'[' x ':=' s ']' t" (at level 20).
Fixpoint subst (x:string) (s:tm) (t:tm) : tm :=
  match t with
  | tvar x' =>
      if beq_string x x' then s else t
  | tabs x' T t1 =>
      tabs x' T (if beq_string x x' then t1 else ([x:=s] t1))
  | tapp t1 t2 =>
      tapp ([x:=s] t1) ([x:=s] t2)
  | ttrue =>
      ttrue
  | tfalse =>
      tfalse
  | tif t1 t2 t3 =>
      tif ([x:=s] t1) ([x:=s] t2) ([x:=s] t3)
  end

where "'[' x ':=' s ']' t" := (subst x s t).



Inductive substi (s:tm) (x:string) : tm -> tm -> Prop :=
  | s_var1 :
      substi s x (tvar x) s
  | s_var2 : forall x', x <> x' ->  
      substi s x (tvar x') (tvar x')
  | s_abs1 : forall T t1 t1', t1 = tabs x T t1' -> 
              substi s x (tabs x T t1') t1
  | s_abs2 : forall x' T t1 t1', x<>x'->
    substi s x t1 t1' ->
    substi s x (tabs x' T t1) (tabs x' T t1')
  | s_app : forall t1 t1' t2 t2', 
       substi s x t1' t1 ->  substi s x t2' t2 ->
         substi s x (tapp t1' t2') (tapp t1 t2)
  | s_true : substi s x ttrue ttrue
  | s_false : substi s x tfalse tfalse
  | s_if :  forall t1 t2 t3 t1' t2' t3',
     substi s x t1 t1' -> substi s x t2 t2' 
     -> substi s x t3 t3' ->
     substi s x (tif t1 t2 t3) (tif t1' t2' t3').

Theorem ex_falso_quodlibet : forall (P:Prop),
  False -> P.
Proof.
Admitted.

Hint Constructors substi.


Theorem substi_correct : forall s x t t',
  [x:=s]t = t' <-> substi s x t t'.
Proof.
intros s x t t'.
split.
- generalize dependent t'. induction t.
 + intros. 
   simpl in H. unfold beq_string in H.
   destruct (string_dec x s0) in H. 
  * rewrite e,H. apply s_var1.
  * rewrite <- H. apply s_var2. 
    assumption.
 + intros. simpl in H. rewrite <- H.
   apply s_app. 
  * apply IHt1. reflexivity.
  * apply IHt2. reflexivity.
 + intros. simpl in H. 
   unfold beq_string in H.
   destruct (string_dec x s0) in H.
  * rewrite <- e. apply s_abs1. 
    rewrite e,H. reflexivity.
  * rewrite <- H. apply s_abs2.
    apply n. apply IHt. reflexivity.
 + intros. rewrite <- H. simpl. 
   apply s_true.
 + intros. rewrite <-H. simpl. 
   apply s_false.
 + intros. rewrite <- H.
   simpl. apply s_if.
  * apply IHt1. reflexivity.
  * apply IHt2. reflexivity.
  * apply IHt3. reflexivity.
- generalize dependent t'. 
  induction t; intros t' H.
 + inversion H. subst. 
  * simpl. unfold beq_string.
    destruct (string_dec s0 s0).
    reflexivity. apply ex_falso_quodlibet.
    apply n. reflexivity.
  * simpl. unfold beq_string.
    destruct (string_dec x s0).
    subst. apply ex_falso_quodlibet.
    apply H1. reflexivity.
    reflexivity.
 + inversion H. subst. simpl. 
   apply IHt1 in H2. apply IHt2 in H4.
   rewrite H2, H4. reflexivity.
 + inversion H. subst. simpl.
   unfold beq_string. 
   destruct (string_dec s0 s0). 
   reflexivity.
   apply ex_falso_quodlibet. apply n.
   reflexivity. subst. apply IHt in H5.
   rewrite <- H5. simpl. 
   unfold beq_string. 
   destruct (string_dec x s0).
   apply ex_falso_quodlibet. apply H4. apply e.
   reflexivity.
 + simpl. inversion H. reflexivity.
 + simpl. inversion H. reflexivity.
 + simpl. inversion H. subst. 
   apply IHt1 in H3. apply IHt2 in H5.
   apply IHt3 in H6. subst. reflexivity.
Qed.


Reserved Notation "t1 '-->' t2" (at level 40).
Inductive step : tm ->tm ->Prop :=
  | ST_AppAbs : forall x T t12 v2,
         value v2 ->
         (tapp (tabs x T t12) v2) --> [x:=v2]t12
  | ST_App1 : forall t1 t1' t2,
         t1 --> t1' ->
         tapp t1 t2 --> tapp t1' t2
  | ST_App2 : forall v1 t2 t2',
         value v1 ->
         t2 --> t2' ->
         tapp v1 t2 --> tapp v1 t2'
  | ST_IfTrue : forall t1 t2,
      (tif ttrue t1 t2) --> t1
  | ST_IfFalse : forall t1 t2,
      (tif tfalse t1 t2) --> t2
  | ST_If : forall t1 t1' t2 t3,
      t1 --> t1' ->
      (tif t1 t2 t3) --> (tif t1' t2 t3)

where "t1 '-->' t2" := (step t1 t2).
Hint Constructors step.
Notation multistep := (multi step).
Notation "t1 '-->*' t2" := (multistep t1 t2) (at level 40).

Lemma step_example1 :
  (tapp idBB idB) -->* idB.
Proof.
  eapply multi_step.
    apply ST_AppAbs.
    apply v_abs.
  simpl.
  apply multi_refl. Qed.

Lemma step_example2 :
  (tapp idBB (tapp idBB idB)) -->* idB.
Proof.
  eapply multi_step.
    apply ST_App2. auto.
    apply ST_AppAbs. auto.
  eapply multi_step.
    apply ST_AppAbs. simpl. auto.
  simpl. apply multi_refl. Qed.

Lemma step_example3 :
  tapp (tapp idBB notB) ttrue -->* tfalse.
Proof.
  eapply multi_step.
    apply ST_App1. apply ST_AppAbs. auto. simpl.
  eapply multi_step.
    apply ST_AppAbs. auto. simpl.
  eapply multi_step.
    apply ST_IfTrue. apply multi_refl. Qed.

Lemma step_example4 :
  tapp idBB (tapp notB ttrue) -->* tfalse.
Proof.
eapply multi_step. 
apply ST_App2. auto.
apply ST_AppAbs. auto.
eapply multi_step. simpl.
apply ST_App2. auto.
apply ST_IfTrue.
eapply multi_step.
apply ST_AppAbs. auto.
simpl. apply multi_refl.
Qed.

Lemma step_example5 :
   tapp (tapp idBBBB idBB) idB
  -->* idB.
Proof.
eapply multi_step.
apply ST_App1.  
apply ST_App2.
Admitted.

(* Lemma step_example1' :
  (tapp idBB idB) -->* idB.
Proof. normalize. Qed.
Lemma step_example2' :
  (tapp idBB (tapp idBB idB)) -->* idB.
Proof. normalize. Qed. *)
(* Lemma step_example3' :
  tapp (tapp idBB notB) ttrue -->* tfalse.
Proof. normalize. Qed.
Lemma step_example4' :
  tapp idBB (tapp notB ttrue) -->* tfalse.
Proof. normalize. Qed.

Lemma step_example5_with_normalize :
       tapp (tapp idBBBB idBB) idB
  -->* idB.
Proof. 
normalize. 
Qed. *)


Definition context := partial_map ty.

Reserved Notation "Gamma '|-' t 'in' T" (at level 40).
Inductive has_type : context -> tm -> ty -> Prop :=
  | T_Var : forall Gamma x T,
      Gamma x = Some T ->
      Gamma |- tvar x in T
  | T_Abs : forall Gamma x T11 T12 t12,
      (update Gamma x T11) |- t12 in T12 ->
      Gamma |- tabs x T11 t12 in TArrow T11 T12
  | T_App : forall T11 T12 Gamma t1 t2,
      Gamma |- t1 in TArrow T11 T12 ->
      Gamma |- t2 in T11 ->
      Gamma |- tapp t1 t2 in T12
  | T_True : forall Gamma,
       Gamma |- ttrue in TBool
  | T_False : forall Gamma,
       Gamma |- tfalse in TBool
  | T_If : forall t1 t2 t3 T Gamma,
       Gamma |- t1 in TBool ->
       Gamma |- t2 in T ->
       Gamma |- t3 in T ->
       Gamma |- tif t1 t2 t3 in T

where "Gamma '|-' t 'in' T" := (has_type Gamma t T).
Hint Constructors has_type.

Example typing_example_1 :
  empty |- tabs x TBool (tvar x) in TArrow TBool TBool.
Proof.
  apply T_Abs. apply T_Var. reflexivity. Qed.

Example typing_example_2 :
  empty |-
    (tabs x TBool
       (tabs y (TArrow TBool TBool)
          (tapp (tvar y) (tapp (tvar y) (tvar x))))) in
    (TArrow TBool (TArrow (TArrow TBool TBool) TBool)).
Proof with auto using update_eq.
  apply T_Abs.
  apply T_Abs.
  eapply T_App. apply T_Var...
  eapply T_App. apply T_Var...
  apply T_Var...
Qed.

(* types is not done totally*)


End STLC.










