WITH sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        d.d_year,
        t.t_hour,
        s.s_store_id,
        s.s_state,
        i.i_item_id,
        i.i_units,
        i.i_current_price,
        ca.ca_state AS ca_state,
        cd.cd_gender,
        ib.ib_lower_bound
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound > 50000
      AND i.i_units = 'Carton'
      AND ca.ca_state = 'NY'
      AND i.i_current_price > (
          SELECT MIN(i2.i_current_price)
          FROM item i2
          WHERE i2.i_category_id = 3
      )
),
store_ret AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        d.d_year,
        t.t_hour,
        s.s_store_id,
        i.i_item_id,
        ib.ib_lower_bound
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound > 50000
),
catalog_ret AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_return_amount,
        d.d_year,
        t.t_hour,
        ib.ib_lower_bound,
        sm.sm_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND ib.ib_lower_bound > 50000
),
web_ret AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_return_amt,
        d.d_year,
        t.t_hour,
        ib.ib_lower_bound,
        wp.wp_type
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND ib.ib_lower_bound > 50000
),
site_info AS (
    SELECT ws.web_site_id,
           d_open.d_year AS open_year,
           d_close.d_year AS close_year
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_open.d_year = 2001
),
all_returns AS (
    SELECT sr.sr_store_sk AS store_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_return_amt AS return_amt
    FROM store_ret sr
    UNION DISTINCT
    SELECT NULL AS store_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_amount AS return_amt
    FROM catalog_ret cr
    UNION DISTINCT
    SELECT NULL AS store_sk,
           wr.wr_item_sk AS item_sk,
           wr.wr_return_amt AS return_amt
    FROM web_ret wr
),
agg_returns AS (
    SELECT
        COALESCE(s.s_store_id, 'ALL') AS store_id,
        COALESCE(i.i_item_id, 'ALL') AS item_id,
        SUM(ar.return_amt) AS total_return_amount,
        CASE WHEN SUM(ar.return_amt) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
        GROUPING(s.s_store_id) AS grp_store,
        GROUPING(i.i_item_id) AS grp_item
    FROM all_returns ar
    LEFT JOIN store s ON ar.store_sk = s.s_store_sk
    LEFT JOIN item i ON ar.item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
        (s.s_store_id, i.i_item_id),
        (s.s_store_id),
        (i.i_item_id)
    )
),
agg_sales AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_store_id, i.i_item_id
)
SELECT
    COALESCE(r.store_id, s.store_id) AS store_id,
    COALESCE(r.item_id, s.item_id) AS item_id,
    r.total_return_amount,
    s.total_sales_amount,
    r.return_level,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(r.store_id, s.store_id)
                       ORDER BY r.total_return_amount DESC NULLS LAST) AS return_rank
FROM agg_returns r
FULL OUTER JOIN agg_sales s
  ON r.store_id = s.store_id
 AND r.item_id = s.item_id
ORDER BY return_rank
LIMIT 100
