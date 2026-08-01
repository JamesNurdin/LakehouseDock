WITH
  -- ==== Air shipping mode ==== 
  cs_base_air AS (
    SELECT
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_net_paid
    FROM catalog_sales cs
  ),
  cs_join_air AS (
    SELECT
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_net_paid,
      w.w_warehouse_id,
      sm.sm_type,
      hd_bill.hd_income_band_sk AS hd_bill_income_band_sk,
      hd_ship.hd_income_band_sk AS hd_ship_income_band_sk
    FROM cs_base_air cs
    INNER JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  ),
  cs_income_air AS (
    SELECT
      cj.w_warehouse_id,
      ib1.ib_income_band_sk,
      SUM(cj.cs_net_paid) AS total_net_paid
    FROM cs_join_air cj
    INNER JOIN income_band ib1
      ON cj.hd_bill_income_band_sk = ib1.ib_income_band_sk
    WHERE cj.sm_type = 'AIR'
    GROUP BY cj.w_warehouse_id, ib1.ib_income_band_sk
  ),
  sr_base_air AS (
    SELECT
      sr.sr_hdemo_sk,
      sr.sr_net_loss
    FROM store_returns sr
  ),
  sr_join_air AS (
    SELECT
      sr.sr_net_loss,
      hd_sr.hd_income_band_sk AS hd_sr_income_band_sk
    FROM sr_base_air sr
    INNER JOIN household_demographics hd_sr
      ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  ),
  sr_income_air AS (
    SELECT
      ib2.ib_income_band_sk,
      SUM(sj.sr_net_loss) AS total_net_loss
    FROM sr_join_air sj
    INNER JOIN income_band ib2
      ON sj.hd_sr_income_band_sk = ib2.ib_income_band_sk
    GROUP BY ib2.ib_income_band_sk
  ),
  wr_base_air AS (
    SELECT
      wr.wr_refunded_hdemo_sk,
      wr.wr_returning_hdemo_sk,
      wr.wr_net_loss
    FROM web_returns wr
  ),
  wr_join_air AS (
    SELECT
      wr.wr_net_loss,
      hd_ref.hd_income_band_sk AS hd_ref_income_band_sk,
      hd_ret.hd_income_band_sk AS hd_ret_income_band_sk
    FROM wr_base_air wr
    INNER JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    INNER JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  ),
  wr_income_air AS (
    SELECT
      ib3.ib_income_band_sk,
      SUM(wj.wr_net_loss) AS total_web_net_loss
    FROM wr_join_air wj
    INNER JOIN income_band ib3
      ON wj.hd_ref_income_band_sk = ib3.ib_income_band_sk
    GROUP BY ib3.ib_income_band_sk
  ),
  base_air AS (
    SELECT
      c.w_warehouse_id,
      c.ib_income_band_sk,
      c.total_net_paid,
      s.total_net_loss,
      w.total_web_net_loss
    FROM cs_income_air c
    FULL OUTER JOIN sr_income_air s
      ON c.ib_income_band_sk = s.ib_income_band_sk
    FULL OUTER JOIN wr_income_air w
      ON c.ib_income_band_sk = w.ib_income_band_sk
  ),
  -- ==== Ground shipping mode ==== 
  cs_base_ground AS (
    SELECT
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_net_paid
    FROM catalog_sales cs
  ),
  cs_join_ground AS (
    SELECT
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_net_paid,
      w.w_warehouse_id,
      sm.sm_type,
      hd_bill.hd_income_band_sk AS hd_bill_income_band_sk,
      hd_ship.hd_income_band_sk AS hd_ship_income_band_sk
    FROM cs_base_ground cs
    INNER JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  ),
  cs_income_ground AS (
    SELECT
      cj.w_warehouse_id,
      ib1.ib_income_band_sk,
      SUM(cj.cs_net_paid) AS total_net_paid
    FROM cs_join_ground cj
    INNER JOIN income_band ib1
      ON cj.hd_bill_income_band_sk = ib1.ib_income_band_sk
    WHERE cj.sm_type = 'GROUND'
    GROUP BY cj.w_warehouse_id, ib1.ib_income_band_sk
  ),
  sr_base_ground AS (
    SELECT
      sr.sr_hdemo_sk,
      sr.sr_net_loss
    FROM store_returns sr
  ),
  sr_join_ground AS (
    SELECT
      sr.sr_net_loss,
      hd_sr.hd_income_band_sk AS hd_sr_income_band_sk
    FROM sr_base_ground sr
    INNER JOIN household_demographics hd_sr
      ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  ),
  sr_income_ground AS (
    SELECT
      ib2.ib_income_band_sk,
      SUM(sj.sr_net_loss) AS total_net_loss
    FROM sr_join_ground sj
    INNER JOIN income_band ib2
      ON sj.hd_sr_income_band_sk = ib2.ib_income_band_sk
    GROUP BY ib2.ib_income_band_sk
  ),
  wr_base_ground AS (
    SELECT
      wr.wr_refunded_hdemo_sk,
      wr.wr_returning_hdemo_sk,
      wr.wr_net_loss
    FROM web_returns wr
  ),
  wr_join_ground AS (
    SELECT
      wr.wr_net_loss,
      hd_ref.hd_income_band_sk AS hd_ref_income_band_sk,
      hd_ret.hd_income_band_sk AS hd_ret_income_band_sk
    FROM wr_base_ground wr
    INNER JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    INNER JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  ),
  wr_income_ground AS (
    SELECT
      ib3.ib_income_band_sk,
      SUM(wj.wr_net_loss) AS total_web_net_loss
    FROM wr_join_ground wj
    INNER JOIN income_band ib3
      ON wj.hd_ref_income_band_sk = ib3.ib_income_band_sk
    GROUP BY ib3.ib_income_band_sk
  ),
  base_ground AS (
    SELECT
      c.w_warehouse_id,
      c.ib_income_band_sk,
      c.total_net_paid,
      s.total_net_loss,
      w.total_web_net_loss
    FROM cs_income_ground c
    FULL OUTER JOIN sr_income_ground s
      ON c.ib_income_band_sk = s.ib_income_band_sk
    FULL OUTER JOIN wr_income_ground w
      ON c.ib_income_band_sk = w.ib_income_band_sk
  ),
  combined AS (
    SELECT * FROM base_air
    UNION DISTINCT
    SELECT * FROM base_ground
  )
SELECT
  w_warehouse_id,
  ib_income_band_sk,
  total_net_paid,
  total_net_loss,
  total_web_net_loss,
  RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
FROM combined
ORDER BY total_net_paid DESC
LIMIT 100
