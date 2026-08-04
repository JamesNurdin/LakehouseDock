WITH
    date_sample AS (
        SELECT *
        FROM date_dim
        TABLESAMPLE BERNOULLI (10)
    ),
    intersect_dates AS (
        SELECT d.d_date
        FROM date_sample d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        INTERSECT
        SELECT d2.d_date
        FROM date_sample d2
        JOIN web_sales ws ON ws.ws_sold_date_sk = d2.d_date_sk
    ),
    except_dates AS (
        SELECT d3.d_date
        FROM date_sample d3
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d3.d_date_sk
        EXCEPT
        SELECT d4.d_date
        FROM date_sample d4
        JOIN web_returns wr ON wr.wr_returned_date_sk = d4.d_date_sk
    )
SELECT
    d.d_date,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = ss.ss_item_sk
    ) AS avg_return_amount_for_item,
    CASE WHEN EXISTS (
        SELECT 1
        FROM promotion p_exists
        WHERE p_exists.p_item_sk = ss.ss_item_sk
          AND p_exists.p_discount_active = 'Y'
    ) THEN 1 ELSE 0 END AS has_active_promo,
    COUNT(DISTINCT i.i_item_sk) FILTER (WHERE i.i_current_price <= 100) AS cnt_items_price_le_100
FROM
    date_sample d
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    FULL OUTER JOIN catalog_page cp2
        ON cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
WHERE
    d.d_date IN (SELECT d_date FROM intersect_dates)
    AND d.d_date NOT IN (SELECT d_date FROM except_dates)
    AND ss.ss_item_sk NOT IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_current_price > 100
    )
GROUP BY
    d.d_date,
    ss.ss_item_sk
ORDER BY d.d_date DESC
LIMIT 100
