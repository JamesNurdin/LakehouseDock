WITH combined_data AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_item_id,
        i.i_brand,
        cd.cd_gender,
        cd.cd_credit_rating,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        ca.ca_state,
        t.t_hour,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        inv.inv_quantity_on_hand,
        w.w_city,
        p.p_cost,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Mid' END AS income_category
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cd.cd_credit_rating = 'Good'
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc LIKE '%damaged%'
      AND ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 8 AND 17
      AND p.p_discount_active = 'Y'
      AND w.w_city = 'Los Angeles'
      AND d_ret.d_month_seq = 1
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_cost > 1000
      )
    UNION ALL
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_item_id,
        i.i_brand,
        cd.cd_gender,
        cd.cd_credit_rating,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        ca.ca_state,
        t.t_hour,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        inv.inv_quantity_on_hand,
        w.w_city,
        p.p_cost,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Mid' END AS income_category
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cd.cd_credit_rating = 'Good'
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc LIKE '%damaged%'
      AND ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 8 AND 17
      AND p.p_discount_active = 'Y'
      AND w.w_city = 'Los Angeles'
      AND d_ret.d_month_seq = 2
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_cost > 1000
      )
)
SELECT
    cd_gender,
    income_category,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_on_hand_quantity,
    COUNT(DISTINCT i_item_id) AS distinct_items
FROM combined_data
GROUP BY cd_gender, income_category
HAVING SUM(sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
