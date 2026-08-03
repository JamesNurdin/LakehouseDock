WITH returns_excluding AS (
    SELECT ss_item_sk
    FROM store_sales
    EXCEPT
    SELECT sr_item_sk
    FROM store_returns
)
SELECT
    d.d_year,
    p.p_promo_name,
    cd.cd_gender,
    SUM(ss.ss_net_paid)                     AS total_net_paid,
    SUM(ss.ss_net_profit)                   AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number)     AS num_transactions,
    (
        SELECT COALESCE(SUM(wr_inner.wr_return_amt), 0)
        FROM web_returns wr_inner
        JOIN date_dim dw_inner ON wr_inner.wr_returned_date_sk = dw_inner.d_date_sk
        WHERE dw_inner.d_year = d.d_year
    )                                        AS web_return_amount_year
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                    AND sr.sr_returned_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE ss.ss_item_sk IN (SELECT ss_item_sk FROM returns_excluding)
GROUP BY ROLLUP (d.d_year, p.p_promo_name, cd.cd_gender)
HAVING SUM(ss.ss_net_paid) > 0
ORDER BY d.d_year DESC, total_net_paid DESC
LIMIT 100
