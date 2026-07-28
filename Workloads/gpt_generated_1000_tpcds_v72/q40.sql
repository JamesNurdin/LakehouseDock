WITH joined AS (
    SELECT
        c.c_customer_id AS customer_id,
        cp.cp_catalog_page_id AS catalog_page_id,
        cs.cs_net_profit AS sales_profit,
        cr.cr_net_loss AS return_loss
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND cp.cp_department = 'Sports'
      AND i.i_brand = 'Brand#12'
      AND p.p_channel_tv = 'N'
      AND w.w_state = 'CA'
      AND wp.wp_type = 'A'
      AND cr.cr_return_quantity > 0
),
agg AS (
    SELECT
        customer_id,
        catalog_page_id,
        SUM(sales_profit) AS total_sales_profit,
        SUM(return_loss) AS total_return_loss,
        SUM(sales_profit) - SUM(return_loss) AS net_contribution
    FROM joined
    GROUP BY GROUPING SETS (
        (customer_id, catalog_page_id),
        (customer_id),
        (catalog_page_id),
        ()
    )
)
SELECT
    COALESCE(customer_id, 'ALL_CUSTOMERS') AS customer_id,
    COALESCE(catalog_page_id, 'ALL_PAGES') AS catalog_page_id,
    total_sales_profit,
    total_return_loss,
    net_contribution,
    RANK() OVER (PARTITION BY catalog_page_id ORDER BY net_contribution DESC) AS profit_rank
FROM agg
WHERE catalog_page_id IS NOT NULL
ORDER BY net_contribution DESC
LIMIT 100
