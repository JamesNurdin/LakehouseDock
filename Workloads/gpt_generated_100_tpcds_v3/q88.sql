WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d_sales.d_year AS year,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cs.cs_ext_discount_amt) + SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        AVG(ib.ib_upper_bound) AS avg_income_upper_bound
    FROM
        catalog_sales cs
        JOIN date_dim d_sales
            ON cs.cs_sold_date_sk = d_sales.d_date_sk
        JOIN time_dim t_sales
            ON cs.cs_sold_time_sk = t_sales.t_time_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
            AND cc.cc_closed_date_sk = d_sales.d_date_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_returned_date_sk = d_sales.d_date_sk
            AND cr.cr_returned_time_sk = t_sales.t_time_sk
        JOIN store s
            ON s.s_closed_date_sk = d_sales.d_date_sk
        JOIN web_sales ws
            ON ws.ws_sold_date_sk = d_sales.d_date_sk
            AND ws.ws_sold_time_sk = t_sales.t_time_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
            AND ws.ws_promo_sk = p.p_promo_sk
    WHERE
        d_sales.d_year BETWEEN 2000 AND 2002
        AND p.p_discount_active = 'Y'
        AND cc.cc_manager = 'Gregory Altman'
        AND s.s_country = 'United States'
        AND ib.ib_upper_bound >= 50000
        AND ws.ws_quantity > 1
        AND cs.cs_quantity > 2
    GROUP BY
        s.s_store_id,
        d_sales.d_year
)
SELECT
    store_id,
    year,
    num_catalog_orders,
    catalog_net_profit,
    web_net_profit,
    total_discount,
    total_return_loss,
    distinct_customers,
    avg_income_upper_bound,
    (catalog_net_profit + web_net_profit - total_return_loss) AS net_profit_after_returns,
    (catalog_net_profit + web_net_profit) / NULLIF(num_catalog_orders, 0) AS avg_profit_per_order
FROM
    sales_agg
WHERE
    (catalog_net_profit + web_net_profit) > 100000
    AND (catalog_net_profit + web_net_profit - total_return_loss) > 0
ORDER BY
    net_profit_after_returns DESC
LIMIT 100
