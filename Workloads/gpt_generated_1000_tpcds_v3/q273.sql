WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        i.i_product_name,
        d_sold.d_year,
        cc.cc_state,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN income_band ib ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr_ret ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
    JOIN time_dim t_cr_ret ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ship.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year BETWEEN 1999 AND 2001
      AND cs.cs_quantity > 50
      AND i.i_current_price BETWEEN 10 AND 1000
      AND cc.cc_state = 'CA'
      AND ib.ib_upper_bound > 50000
      AND t_sold.t_hour BETWEEN 9 AND 17
      AND r.r_reason_desc != 'Damaged'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
          WHERE wr.wr_item_sk = i.i_item_sk
            AND d_wr.d_year = d_sold.d_year
            AND wr.wr_return_quantity > 0
      )
    GROUP BY
        i.i_item_id,
        i.i_item_sk,
        i.i_product_name,
        d_sold.d_year,
        cc.cc_state,
        ib.ib_upper_bound
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.d_year,
    sa.cc_state,
    sa.total_net_profit,
    sa.total_return_amount,
    sa.num_returns,
    sa.total_quantity_sold,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank,
    CASE WHEN sa.ib_upper_bound >= 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        WHERE wr.wr_item_sk = sa.i_item_sk
          AND d_wr.d_year = sa.d_year
    ) AS web_return_count
FROM sales_agg sa
ORDER BY sa.total_net_profit DESC
LIMIT 100
