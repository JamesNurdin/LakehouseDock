/*
Goal: Analyze total net paid per sales year and promotion, ranking promotions within each year, with subtotals, while filtering on active promotions, a specific call‑center class, warehouses in CA, sales in year 2001 and high‑value catalog sales, and keep only store‑sales rows that have no matching store return.
*/
WITH raw AS (
    SELECT
        d_sales.d_year AS sales_year,
        p_ss.p_promo_name AS promo_name,
        cc.cc_name AS call_center_name,
        w.w_state AS warehouse_state,
        ss.ss_net_paid AS ss_net_paid,
        cs.cs_net_paid AS cs_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        latest.latest_promo_name
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_date_sk = d_sales.d_date_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d_sales.d_date_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_name AS latest_promo_name
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
        ORDER BY p2.p_start_date_sk DESC
        LIMIT 1
    ) latest
    WHERE d_sales.d_year = 2001
      AND p_ss.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND cc.cc_class = 'CLASS1'
      AND cs.cs_net_paid > 1000
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
              AND sr.sr_item_sk = ss.ss_item_sk
        )
),
aggregated AS (
    SELECT
        sales_year,
        promo_name,
        call_center_name,
        warehouse_state,
        SUM(ss_net_paid) AS sum_ss_net_paid,
        SUM(cs_net_paid) AS sum_cs_net_paid,
        SUM(ws_net_paid) AS sum_ws_net_paid,
        SUM(ss_net_paid + cs_net_paid + ws_net_paid) AS total_net_paid
    FROM raw
    GROUP BY ROLLUP (sales_year, promo_name, call_center_name, warehouse_state)
)
SELECT
    sales_year,
    promo_name,
    call_center_name,
    warehouse_state,
    total_net_paid,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_net_paid DESC) AS rank_in_year,
    SUM(total_net_paid) OVER (
        PARTITION BY sales_year
        ORDER BY total_net_paid
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_total
FROM aggregated
ORDER BY sales_year NULLS LAST, total_net_paid DESC
LIMIT 100
