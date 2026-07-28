WITH store_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_promo_sk AS promo_sk,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_promo_sk
)
SELECT
    d_sold.d_year,
    p.p_promo_name,
    SUM(cs.cs_net_paid_inc_ship)      AS total_catalog_net_paid,
    SUM(cs.cs_net_profit)             AS total_catalog_profit,
    SUM(wr.wr_net_loss)               AS total_web_returns_loss,
    sa.total_store_net_paid,
    sa.total_store_profit
FROM store_agg sa
JOIN date_dim d_sold        ON sa.date_sk = d_sold.d_date_sk
JOIN promotion p            ON sa.promo_sk = p.p_promo_sk
JOIN catalog_sales cs       ON cs.cs_sold_date_sk = d_sold.d_date_sk
                              AND cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN date_dim d_ship            ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr            ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN web_site ws               ON ws.web_open_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND p.p_channel_email = 'N'
  AND cs.cs_net_paid_inc_ship > (
        SELECT AVG(cs2.cs_net_paid_inc_ship)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = d_sold.d_date_sk
    )
GROUP BY d_sold.d_year, p.p_promo_name, sa.total_store_net_paid, sa.total_store_profit
ORDER BY total_catalog_net_paid DESC
LIMIT 100
