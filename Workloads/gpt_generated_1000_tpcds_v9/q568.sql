WITH sales_agg AS (
    SELECT
        s.s_store_id,
        i.i_category,
        d.d_year,
        SUM(ss.ss_net_paid)                         AS store_net_paid,
        SUM(cs.cs_net_paid)                         AS catalog_net_paid,
        SUM(ws.ws_net_paid)                         AS web_net_paid,
        SUM(COALESCE(wr.wr_net_loss, 0))            AS web_returns_loss,
        COUNT(DISTINCT ss.ss_ticket_number)         AS store_transactions,
        COUNT(DISTINCT cs.cs_order_number)          AS catalog_transactions,
        COUNT(DISTINCT ws.ws_order_number)          AS web_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk

    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND p.p_discount_active = 'N'
      AND ca.ca_location_type = 'apartment'
      AND t.t_hour BETWEEN 9 AND 18
    GROUP BY ROLLUP (s.s_store_id, i.i_category, d.d_year)
)
SELECT
    s_store_id,
    i_category,
    d_year,
    store_net_paid,
    catalog_net_paid,
    web_net_paid,
    web_returns_loss,
    total_profit,
    profit_rank,
    store_perf,
    max_store_net_paid
FROM (
    SELECT
        s_store_id,
        i_category,
        d_year,
        store_net_paid,
        catalog_net_paid,
        web_net_paid,
        web_returns_loss,
        (store_net_paid + catalog_net_paid + web_net_paid - web_returns_loss) AS total_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY (store_net_paid + catalog_net_paid + web_net_paid - web_returns_loss) DESC) AS profit_rank,
        CASE WHEN store_net_paid > 0 THEN 'POSITIVE' ELSE 'NONPOSITIVE' END AS store_perf,
        (SELECT MAX(store_net_paid) FROM sales_agg WHERE d_year = 2001) AS max_store_net_paid
    FROM sales_agg
    WHERE i_category IS NOT NULL

    UNION ALL

    SELECT
        s_store_id,
        i_category,
        d_year,
        store_net_paid,
        catalog_net_paid,
        web_net_paid,
        web_returns_loss,
        (store_net_paid + catalog_net_paid + web_net_paid - web_returns_loss) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY d_year ORDER BY (store_net_paid + catalog_net_paid + web_net_paid - web_returns_loss) DESC) AS profit_rank,
        CASE WHEN catalog_net_paid > 0 THEN 'CAT_POS' ELSE 'CAT_NEG' END AS store_perf,
        (SELECT MIN(catalog_net_paid) FROM sales_agg WHERE d_year = 2001) AS max_store_net_paid
    FROM sales_agg
    WHERE store_net_paid > 0
) combined
ORDER BY d_year, profit_rank
LIMIT 100
