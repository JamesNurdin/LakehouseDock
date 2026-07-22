WITH sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS sales_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_bill_addr_sk AS address_sk,
        cs.cs_net_profit AS net_profit,
        CAST(NULL AS integer) AS web_site_sk,
        CAST(NULL AS integer) AS web_page_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sales_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_warehouse_sk AS warehouse_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_bill_addr_sk AS address_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_web_site_sk AS web_site_sk,
        ws.ws_web_page_sk AS web_page_sk
    FROM web_sales ws
),
aggregated AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        p.p_promo_name,
        c.c_customer_id,
        ca.ca_city,
        p.p_discount_active,
        d.d_date,
        SUM(su.net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM sales_union su
    JOIN date_dim d ON su.sales_date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    JOIN warehouse w ON su.warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON su.promo_sk = p.p_promo_sk
    JOIN customer c ON su.customer_sk = c.c_customer_sk
    JOIN customer_address ca ON su.address_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_site we
        ON su.web_site_sk = we.web_site_sk
    WHERE d.d_year = 2002
      AND i.i_category = 'Electronics'
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND (su.web_page_sk IS NULL OR EXISTS (
           SELECT 1
           FROM web_page wp
           WHERE wp.wp_web_page_sk = su.web_page_sk
             AND wp.wp_type = 'Home'
      ))
    GROUP BY
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        p.p_promo_name,
        c.c_customer_id,
        ca.ca_city,
        p.p_discount_active,
        d.d_date
)
SELECT
    d_year,
    i_item_id,
    i_product_name,
    w_warehouse_name,
    p_promo_name,
    c_customer_id,
    ca_city,
    CASE WHEN p_discount_active = 'Y' THEN 'Active Promotion' ELSE 'Inactive Promotion' END AS promo_status,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY i_item_id ORDER BY d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_total_net_profit
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
