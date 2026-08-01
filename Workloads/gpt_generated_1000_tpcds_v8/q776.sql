WITH
sampled_items AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
),

catalog_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d.d_date,
        cs.cs_sold_time_sk,
        t.t_hour AS sold_hour,
        cs.cs_item_sk,
        i.i_product_name,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ship_mode_sk,
        sm.sm_type,
        cs.cs_promo_sk,
        p.p_promo_name,
        cs.cs_call_center_sk,
        cc.cc_name,
        cs.cs_bill_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN sampled_items i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND cc.cc_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND i.i_brand = 'Brand#12'
),

store_return_data AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        d.d_date AS return_date,
        sr.sr_return_time_sk,
        t.t_hour AS return_hour,
        sr.sr_item_sk,
        i.i_product_name,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_store_sk,
        s.s_store_name,
        s.s_state,
        sr.sr_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_returns sr
    JOIN sampled_items i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
),

web_sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d.d_date,
        ws.ws_sold_time_sk,
        t.t_hour AS sold_hour,
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        ws.ws_promo_sk,
        p.p_promo_name,
        ws.ws_web_page_sk,
        wp.wp_type,
        ws.ws_bill_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM web_sales ws
    JOIN sampled_items i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'C'
),

catalog_returns_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        d.d_date AS return_date,
        cr.cr_returned_time_sk,
        t.t_hour AS return_hour,
        cr.cr_item_sk,
        i.i_product_name,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cc.cc_name
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN sampled_items i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
),

web_returns_data AS (
    SELECT
        wr.wr_order_number,
        wr.wr_returned_date_sk,
        d.d_date AS return_date,
        wr.wr_returned_time_sk,
        t.t_hour AS return_hour,
        wr.wr_item_sk,
        i.i_product_name,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_web_page_sk,
        wp.wp_type
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN sampled_items i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
),

combined_sales AS (
    SELECT
        COALESCE(cd.cs_order_number, wd.ws_order_number) AS order_number,
        COALESCE(cd.d_date, wd.d_date) AS sale_date,
        COALESCE(cd.i_product_name, wd.i_product_name) AS product_name,
        COALESCE(cd.cs_quantity, wd.ws_quantity) AS quantity,
        COALESCE(cd.cs_net_paid, wd.ws_net_paid) AS net_paid,
        COALESCE(cd.cs_net_profit, wd.ws_net_profit) AS net_profit,
        COALESCE(cd.sm_type, wd.sm_type) AS ship_mode_type,
        COALESCE(cd.p_promo_name, wd.p_promo_name) AS promo_name,
        CASE
            WHEN cd.cs_order_number IS NOT NULL THEN 'Catalog'
            WHEN wd.ws_order_number IS NOT NULL THEN 'Web'
            ELSE 'Unknown'
        END AS channel
    FROM catalog_data cd
    FULL OUTER JOIN web_sales_data wd
        ON cd.cs_order_number = wd.ws_order_number
),

high_value_orders AS (
    SELECT order_number
    FROM combined_sales
    WHERE net_paid > 10000
),

final_agg AS (
    SELECT
        cs.channel,
        cs.sale_date,
        cs.product_name,
        COUNT(DISTINCT cs.order_number) AS distinct_orders,
        SUM(cs.quantity) AS total_quantity,
        SUM(cs.net_paid) AS total_net_paid,
        AVG(cs.net_paid) AS avg_net_paid,
        MAX(cs.net_paid) AS max_net_paid,
        MIN(cs.net_paid) AS min_net_paid,
        RANK() OVER (PARTITION BY cs.channel ORDER BY SUM(cs.net_paid) DESC) AS sales_rank,
        (SELECT COUNT(DISTINCT cs_bill_customer_sk) FROM catalog_sales) AS total_customers
    FROM combined_sales cs
    LEFT JOIN store_return_data sr
        ON cs.order_number = sr.sr_ticket_number
    LEFT JOIN catalog_returns_data cr
        ON cs.order_number = cr.cr_order_number
    LEFT JOIN web_returns_data wr
        ON cs.order_number = wr.wr_order_number
    WHERE sr.sr_ticket_number IS NULL
      AND cr.cr_order_number IS NULL
      AND wr.wr_order_number IS NULL
      AND cs.order_number NOT IN (SELECT order_number FROM high_value_orders)
    GROUP BY cs.channel, cs.sale_date, cs.product_name
    HAVING COUNT(*) > 5
)

SELECT *
FROM final_agg
WHERE channel IN ('Catalog', 'Web')
EXCEPT
SELECT *
FROM (
    SELECT *
    FROM final_agg
    WHERE total_net_paid < 0
) neg
ORDER BY total_net_paid DESC
LIMIT 100
