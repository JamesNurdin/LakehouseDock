WITH
-- Sales fact with all possible dimension joins
sales AS (
    SELECT
        cs.cs_item_sk               AS item_sk,
        cs.cs_ext_sales_price       AS amount,
        NULL                        AS reason_desc,
        cs.cs_sold_time_sk          AS time_sk,
        i.i_brand                   AS brand,
        cp.cp_type                  AS catalog_type,
        cc.cc_name                  AS call_center_name,
        w.w_warehouse_name          AS warehouse_name,
        cd.cd_gender                AS customer_gender,
        hd.hd_buy_potential         AS household_buy_pot,
        ib.ib_lower_bound           AS income_low,
        ib.ib_upper_bound           AS income_high,
        t.t_hour                    AS hour_of_day,
        t.t_am_pm                   AS am_pm
    FROM catalog_sales cs
    JOIN item i                     ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc             ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w                ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd   ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t                 ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
      AND t.t_hour BETWEEN 12 AND 18
      AND i.i_brand_id BETWEEN 10 AND 20
      AND cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 100
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451145
),

-- Store‑return fact, using FULL OUTER JOIN with ITEM as required
store_ret AS (
    SELECT
        sr.sr_item_sk               AS item_sk,
        sr.sr_return_amt            AS amount,
        r.r_reason_desc             AS reason_desc,
        sr.sr_return_time_sk        AS time_sk,
        i.i_brand                   AS brand,
        s.s_store_name              AS store_name,
        cd.cd_gender                AS customer_gender,
        hd.hd_buy_potential         AS household_buy_pot,
        ib.ib_lower_bound           AS income_low,
        ib.ib_upper_bound           AS income_high,
        t.t_hour                    AS hour_of_day,
        t.t_am_pm                   AS am_pm
    FROM store_returns sr
    FULL OUTER JOIN item i               ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r                        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s                         ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd       ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t                     ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
      AND t.t_hour BETWEEN 12 AND 18
      AND i.i_brand_id BETWEEN 10 AND 20
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 50
      AND sr.sr_returned_date_sk BETWEEN 2450815 AND 2451145
),

-- Web‑return fact, joining every remaining dimension
web_ret AS (
    SELECT
        wr.wr_item_sk               AS item_sk,
        wr.wr_return_amt            AS amount,
        r.r_reason_desc             AS reason_desc,
        wr.wr_returned_time_sk      AS time_sk,
        i.i_brand                   AS brand,
        wp.wp_url                   AS web_page_url,
        cd.cd_gender                AS cust_gender_refunded,
        cd2.cd_gender               AS cust_gender_returning,
        hd.hd_buy_potential         AS hh_buy_pot_refunded,
        hd2.hd_buy_potential        AS hh_buy_pot_returning,
        ib.ib_lower_bound           AS income_low_refunded,
        ib2.ib_lower_bound          AS income_low_returning,
        t.t_hour                    AS hour_of_day,
        t.t_am_pm                   AS am_pm
    FROM web_returns wr
    JOIN item i                     ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r                    ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp                ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t                 ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd   ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_demographics cd2  ON wr.wr_returning_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN household_demographics hd2 ON wr.wr_returning_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN income_band ib2            ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE t.t_am_pm = 'PM'
      AND t.t_hour BETWEEN 12 AND 18
      AND i.i_brand_id BETWEEN 10 AND 20
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 50
      AND wr.wr_returned_date_sk BETWEEN 2450815 AND 2451145
),

-- Consolidate the three fact streams (UNION DISTINCT)
union_data AS (
    SELECT item_sk, amount, reason_desc FROM sales
    UNION DISTINCT
    SELECT item_sk, amount, reason_desc FROM store_ret
    UNION DISTINCT
    SELECT item_sk, amount, reason_desc FROM web_ret
),

-- Small helper set for a CROSS JOIN (cartesian product)
bucket AS (
    SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
),

hour_bins AS (
    SELECT DISTINCT t_hour FROM time_dim WHERE t_hour IS NOT NULL LIMIT 5
)
SELECT
    COALESCE(i.i_brand, 'All')               AS brand,
    COALESCE(u.reason_desc, 'All')           AS reason,
    hb.grp,
    SUM(u.amount)                            AS total_amount,
    COUNT(*)                                 AS txn_cnt,
    RANK() OVER (PARTITION BY hb.grp ORDER BY SUM(u.amount) DESC) AS rank_in_grp
FROM union_data u
LEFT JOIN item i          ON u.item_sk = i.i_item_sk
CROSS JOIN bucket hb
CROSS JOIN hour_bins hb2
GROUP BY CUBE (i.i_brand, u.reason_desc), hb.grp
ORDER BY total_amount DESC
LIMIT 100
