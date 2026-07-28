WITH
    store_agg AS (
        SELECT
            s.s_store_name AS s_store_name,
            d.d_year AS d_year,
            'Store' AS channel,
            SUM(ss.ss_net_profit) AS profit,
            SUM(ss.ss_quantity) AS quantity
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2001
          AND s.s_state = 'CA'
          AND i.i_category = 'Electronics'
          AND p.p_discount_active = 'Y'
        GROUP BY s.s_store_name, d.d_year
    ),
    catalog_agg AS (
        SELECT
            NULL AS s_store_name,
            d.d_year AS d_year,
            'Catalog' AS channel,
            SUM(cs.cs_net_profit) AS profit,
            SUM(cs.cs_quantity) AS quantity
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_category = 'Electronics'
          AND p.p_discount_active = 'Y'
          AND cc.cc_class = 'Corporate'
        GROUP BY d.d_year
    ),
    web_agg AS (
        SELECT
            NULL AS s_store_name,
            d.d_year AS d_year,
            'Web' AS channel,
            SUM(ws.ws_net_profit) AS profit,
            SUM(ws.ws_quantity) AS quantity
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_category = 'Electronics'
          AND p.p_discount_active = 'Y'
        GROUP BY d.d_year
    ),
    all_sales AS (
        SELECT * FROM store_agg
        UNION ALL
        SELECT * FROM catalog_agg
        UNION ALL
        SELECT * FROM web_agg
    )
SELECT
    s_store_name,
    channel,
    d_year,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity,
    DENSE_RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM all_sales
GROUP BY ROLLUP(s_store_name, channel, d_year)
ORDER BY profit_rank
LIMIT 100
