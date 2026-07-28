WITH catalog_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        cc.cc_call_center_sk,
        cp.cp_catalog_page_sk,
        w.w_warehouse_sk,
        p.p_promo_sk,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS catalog_txn_cnt
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'Electronic'
    GROUP BY
        d.d_date_sk,
        d.d_year,
        cc.cc_call_center_sk,
        cp.cp_catalog_page_sk,
        w.w_warehouse_sk,
        p.p_promo_sk
),

web_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        w.w_warehouse_sk,
        p.p_promo_sk,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(*) AS web_txn_cnt,
        'web' AS source
    FROM tpcds.date_dim d
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
       AND i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND we.web_class = 'A'
      AND p.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 0
    GROUP BY
        d.d_date_sk,
        d.d_year,
        w.w_warehouse_sk,
        p.p_promo_sk
),

combined AS (
    SELECT
        d_date_sk,
        d_year,
        catalog_profit AS profit,
        catalog_txn_cnt AS txn_cnt,
        'catalog' AS source
    FROM catalog_agg
    UNION ALL
    SELECT
        d_date_sk,
        d_year,
        web_profit AS profit,
        web_txn_cnt AS txn_cnt,
        source
    FROM web_agg
),

store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        sr.sr_returned_date_sk
    FROM tpcds.store s
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
),

final AS (
    SELECT
        c.d_date_sk,
        c.d_year,
        SUM(c.profit) AS total_profit,
        COUNT(*) AS source_cnt,
        ROW_NUMBER() OVER (PARTITION BY c.d_year ORDER BY SUM(c.profit) DESC) AS rn
    FROM combined c
    JOIN tpcds.date_dim d
        ON c.d_date_sk = d.d_date_sk
    JOIN store_info si
        ON d.d_date_sk = si.sr_returned_date_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM tpcds.store_returns sr2
            WHERE sr2.sr_store_sk = si.s_store_sk
              AND sr2.sr_returned_date_sk = d.d_date_sk
        )
      AND si.s_state = 'CA'
    GROUP BY c.d_date_sk, c.d_year
    HAVING SUM(c.profit) > 0
)
SELECT *
FROM final
ORDER BY total_profit DESC
LIMIT 100
