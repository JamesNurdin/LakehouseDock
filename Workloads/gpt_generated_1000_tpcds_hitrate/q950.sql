WITH date_filtered AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
joined_all AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_ticket_number       AS sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cp.cp_department,
        cp.cp_catalog_number,
        p.p_promo_name,
        w.w_warehouse_name,
        ca_ss.ca_state,
        wp.wp_url,
        ws.web_name,
        d_ss.d_year
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    /* join through the date dimension – allowed rule */
    LEFT JOIN date_filtered d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    /* web_returns linked via its own date key */
    LEFT JOIN date_filtered d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_filtered d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    /* web_site linked through the same date used for store_sales */
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_ss.d_date_sk
)
SELECT
    ja.cp_department,
    ja.p_promo_name,
    ja.ca_state,
    ja.d_year,
    SUM(ja.ss_net_paid)           AS total_net_paid,
    SUM(ja.sr_return_amt)         AS total_return_amount,
    COUNT(DISTINCT ja.ss_ticket_number) AS sales_transactions,
    COUNT(DISTINCT ja.sr_ticket_number) AS return_transactions,
    MAX(item_sales.item_total_sales)    AS total_item_sales
FROM joined_all ja
/* LATERAL sub‑query that uses the current row's item key */
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_sales_price) AS item_total_sales
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = ja.ss_item_sk
) AS item_sales
/* small computed set crossed with the result set */
CROSS JOIN (VALUES (1), (2), (3)) AS mult(m)
WHERE ja.ca_state = 'CA'
  AND ja.cp_department = 'Electronics'
  AND ja.p_promo_name = 'Holiday Promo'
  AND ja.d_year = 2001
  AND ja.w_warehouse_name = 'Warehouse 12'
  AND mult.m = 2
  AND ja.ss_quantity > (
        SELECT MAX(cs_quantity)
        FROM catalog_sales
        WHERE cs_sold_date_sk = (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_date = DATE '2001-06-01'
        )
    )
GROUP BY
    ja.cp_department,
    ja.p_promo_name,
    ja.ca_state,
    ja.d_year
ORDER BY total_net_paid DESC
LIMIT 100
