/*
Goal: Analyze return and sales performance by brand, category, catalog department and web site state, combining catalog returns, store returns and web sales. The query joins all ten selected tables, re‑uses the time_dim table under two aliases, uses a full outer join, applies a scalar subquery filter, includes a CASE expression, computes ROW_NUMBER and RANK window functions, and returns the top 100 rows ordered by total return amount.
*/
WITH avg_qty AS (
    SELECT avg(ws2.ws_quantity) AS avg_quantity
    FROM web_sales ws2
    WHERE ws2.ws_sold_date_sk = 2451053
)
SELECT
    i.i_brand,
    i.i_category,
    cp.cp_department,
    wsite.web_state,
    SUM(cr.cr_return_amount)                         AS total_catalog_return,
    SUM(sr.sr_return_amt)                           AS total_store_return,
    SUM(ws.ws_ext_sales_price)                      AS total_web_sales,
    (SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt)) AS total_return_amount,
    CASE WHEN (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) > 0
         THEN 'Loss' ELSE 'Profit' END               AS overall_profit_flag,
    ROW_NUMBER() OVER (ORDER BY (SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt)) DESC) AS rn,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY (SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt)) DESC) AS brand_return_rank
FROM
    inventory inv
    INNER JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    FULL OUTER JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    INNER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    INNER JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    INNER JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
WHERE
    ws.ws_quantity > (SELECT avg_quantity FROM avg_qty)
GROUP BY
    i.i_brand,
    i.i_category,
    cp.cp_department,
    wsite.web_state
ORDER BY
    total_return_amount DESC
LIMIT 100
