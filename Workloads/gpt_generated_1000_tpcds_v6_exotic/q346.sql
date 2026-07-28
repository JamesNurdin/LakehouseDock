WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        d_sold.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    WHERE d_sold.d_year = 2001                                 -- filter 1: specific year
      AND p.p_promo_name IS NOT NULL                           -- filter 2: promotional name present
      AND ws.ws_quantity > 1                                   -- filter 3: more than one item per order
      AND ca_bill.ca_state = 'CA'                              -- filter 4: customers in California
      AND ws.ws_net_paid > 0                                   -- filter 5: paid orders only
      AND ws.ws_ext_sales_price BETWEEN 100 AND 1000           -- filter 6: price range
      AND EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_addr_sk = ca_bill.ca_address_sk
              AND sr.sr_returned_date_sk = d_sold.d_date_sk
              AND sr.sr_refunded_cash > 100
        )                                                      -- semi‑join: at least one return for the address/date
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_addr_sk = ca_bill.ca_address_sk
              AND sr2.sr_refunded_cash > 500
        )                                                      -- anti‑join: exclude high‑refund customers
    GROUP BY ws.ws_web_site_sk, ws.ws_promo_sk, d_sold.d_year
)
SELECT
    ws_site.web_name,
    p.p_promo_name,
    s.d_year,
    s.total_net_profit,
    s.avg_discount,
    s.distinct_orders,
    s.total_quantity,
    (
        SELECT COUNT(DISTINCT p_inner.p_promo_id)
        FROM promotion p_inner
        WHERE p_inner.p_discount_active = 'Y'
    ) AS active_promo_count
FROM sales_agg s
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site ON s.ws_web_site_sk = ws_site.web_site_sk
JOIN (
    SELECT DISTINCT p2.p_promo_name
    FROM promotion p2
    WHERE p2.p_discount_active = 'Y'
) distinct_active_promos
    ON p.p_promo_name = distinct_active_promos.p_promo_name
ORDER BY s.total_net_profit DESC
LIMIT 100
