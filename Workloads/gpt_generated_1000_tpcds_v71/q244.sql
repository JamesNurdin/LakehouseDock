WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(wr.wr_net_loss) AS web_return_loss,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH'
            WHEN SUM(ss.ss_net_profit) BETWEEN 0 AND 10000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM date_dim d
    JOIN store_sales ss               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t                   ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                       ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c                   ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca          ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd     ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p                  ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs            ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp              ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr          ON cr.cr_order_number = cs.cs_order_number
    JOIN inventory inv                ON inv.inv_date_sk = d.d_date_sk
    JOIN web_returns wr              ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND i.i_brand_id = 123
      AND ca.ca_gmt_offset = -5.00
    GROUP BY c.c_customer_sk, c.c_customer_id
),
high_store AS (
    SELECT c_customer_sk FROM sales_agg WHERE store_net_profit > 5000
),
high_catalog AS (
    SELECT c_customer_sk FROM sales_agg WHERE catalog_net_paid > 20000
),
high_value_customers AS (
    SELECT c_customer_sk FROM high_store
    UNION
    SELECT c_customer_sk FROM high_catalog
)
SELECT
    sa.c_customer_id,
    sa.store_net_profit,
    sa.catalog_net_paid,
    sa.web_return_loss,
    sa.catalog_return_loss,
    sa.total_inventory,
    sa.profit_category,
    (SELECT AVG(store_net_profit) FROM sales_agg) AS avg_store_profit
FROM sales_agg sa
JOIN high_value_customers hv ON hv.c_customer_sk = sa.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = sa.c_customer_sk
      AND cr2.cr_return_amount > 500
)
ORDER BY sa.store_net_profit DESC
LIMIT 100
