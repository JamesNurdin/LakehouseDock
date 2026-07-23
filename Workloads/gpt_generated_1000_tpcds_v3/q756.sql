WITH base AS (
    SELECT
        d.d_date,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        r.r_reason_desc,
        cp.cp_type,
        inv.inv_quantity_on_hand,
        ws.ws_quantity AS web_quantity,
        ws.ws_net_paid AS web_net_paid,
        cs.cs_ext_discount_amt
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND s.s_city IN ('Highland Park', 'Mount Pleasant')
      AND i.i_brand = 'BrandX'
      AND cp.cp_type = 'monthly'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = i.i_item_sk
            AND cs2.cs_sold_date_sk = d.d_date_sk
            AND cs2.cs_ext_discount_amt > 10
      )
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_net_profit DESC) AS profit_rank,
        CASE WHEN sr_return_quantity > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag
    FROM base
)
SELECT DISTINCT
    d_date,
    s_store_name,
    s_city,
    i_product_name,
    i_category,
    i_brand,
    i_current_price,
    ss_quantity,
    ss_net_profit,
    profit_rank,
    return_flag,
    (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i_item_sk
    ) AS avg_catalog_discount,
    (
        SELECT COUNT(DISTINCT r2.r_reason_desc)
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_item_sk = i_item_sk
    ) AS distinct_return_reasons
FROM ranked
WHERE profit_rank <= 5
ORDER BY s_store_name, profit_rank
