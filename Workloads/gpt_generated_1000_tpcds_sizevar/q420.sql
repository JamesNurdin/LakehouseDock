WITH
    ss_agg AS (
        SELECT
            ss_sold_date_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            ss_ticket_number,
            ss_item_sk,
            SUM(ss_net_paid) AS total_net_paid,
            COUNT(DISTINCT ss_item_sk) AS distinct_items_sold
        FROM store_sales
        WHERE ss_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2001
        )
        GROUP BY
            ss_sold_date_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            ss_ticket_number,
            ss_item_sk
    ),
    sr_keys AS (
        SELECT sr_ticket_number, sr_item_sk
        FROM store_returns
    ),
    wr_keys AS (
        SELECT wr_order_number AS ticket_number, wr_item_sk
        FROM web_returns
    ),
    common_tickets AS (
        SELECT sr_ticket_number FROM sr_keys
        INTERSECT
        SELECT ticket_number FROM wr_keys
    ),
    store_only_returns AS (
        SELECT sr_ticket_number FROM sr_keys
        EXCEPT
        SELECT ticket_number FROM wr_keys
    )
SELECT
    d_sales.d_year AS sales_year,
    cd_sales.cd_education_status,
    hd_sales.hd_buy_potential,
    ib.ib_lower_bound,
    SUM(s.total_net_paid) AS sum_net_paid,
    COUNT(DISTINCT s.ss_item_sk) AS distinct_items,
    COUNT(DISTINCT cd_sales.cd_demo_sk) AS distinct_customers,
    COUNT(DISTINCT ib.ib_income_band_sk) AS distinct_income_bands,
    COUNT(DISTINCT CASE WHEN sr.sr_ticket_number IS NOT NULL THEN sr.sr_ticket_number END) AS store_return_tickets,
    COUNT(DISTINCT CASE WHEN wr.wr_order_number IS NOT NULL THEN wr.wr_order_number END) AS web_return_orders,
    COUNT(DISTINCT ct.sr_ticket_number) AS common_return_tickets,
    COUNT(DISTINCT sot.sr_ticket_number) AS store_only_return_tickets
FROM ss_agg s
JOIN date_dim d_sales ON s.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_demographics cd_sales ON s.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN household_demographics hd_sales ON s.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN income_band ib ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_ticket_number = s.ss_ticket_number
    AND sr.sr_item_sk = s.ss_item_sk
JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN date_dim dw ON wr.wr_returned_date_sk = dw.d_date_sk
JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
LEFT JOIN common_tickets ct ON ct.sr_ticket_number = sr.sr_ticket_number
LEFT JOIN store_only_returns sot ON sot.sr_ticket_number = sr.sr_ticket_number
WHERE d_sales.d_current_quarter = 'Y'
  AND cd_sales.cd_dep_employed_count > 2
GROUP BY
    d_sales.d_year,
    cd_sales.cd_education_status,
    hd_sales.hd_buy_potential,
    ib.ib_lower_bound
ORDER BY sum_net_paid DESC
LIMIT 100
