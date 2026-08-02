WITH d AS (
    SELECT *
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2002
)
SELECT
    d.d_year AS year,
    ca_store.ca_state AS state,
    hd_store.hd_buy_potential AS buy_potential,
    ws.web_name AS website_name,
    p_start.p_promo_name AS promo_name,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_net_loss,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_net_loss,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_store_return_qty,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_return_qty
FROM store_returns sr
JOIN d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_store ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN web_site ws_close ON ws_close.web_close_date_sk = d.d_date_sk
LEFT JOIN promotion p_start ON p_start.p_start_date_sk = d.d_date_sk
LEFT JOIN promotion p_end ON p_end.p_end_date_sk = d.d_date_sk
WHERE sr.sr_hdemo_sk IN (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_income_band_sk = 5
)
GROUP BY
    d.d_year,
    ca_store.ca_state,
    hd_store.hd_buy_potential,
    ws.web_name,
    p_start.p_promo_name
ORDER BY total_store_net_loss DESC, year ASC
LIMIT 100
