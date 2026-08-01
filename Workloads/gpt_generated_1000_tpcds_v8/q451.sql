WITH
    items_only_sold AS (
        SELECT ss_item_sk FROM store_sales
        EXCEPT
        SELECT wr_item_sk FROM web_returns
    ),
    common_hd AS (
        SELECT ss_hdemo_sk FROM store_sales
        INTERSECT
        SELECT wr_returning_hdemo_sk FROM web_returns
    )
SELECT
    ss.ss_ticket_number,
    cd.cd_gender,
    cd.cd_education_status,
    CASE WHEN cd.cd_credit_rating = 'Good' THEN 'Preferred' ELSE 'Standard' END AS customer_segment,
    d_sale.d_year,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ws.web_name,
    ss.ss_net_paid,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ss.ss_net_paid DESC) AS gender_rank,
    (
        SELECT SUM(ss_sub.ss_ext_sales_price)
        FROM store_sales ss_sub
        WHERE ss_sub.ss_customer_sk = ss.ss_customer_sk
    ) AS total_customer_sales
FROM store_sales ss
JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv ON ss.ss_sold_date_sk = inv.inv_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sale.d_date_sk
WHERE ss.ss_item_sk IN (SELECT ss_item_sk FROM items_only_sold)
  AND hd.hd_demo_sk IN (SELECT ss_hdemo_sk FROM common_hd)
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returning_customer_sk = ss.ss_customer_sk
          AND wr.wr_returned_date_sk = d_sale.d_date_sk
    )
GROUP BY
    ss.ss_ticket_number,
    cd.cd_gender,
    cd.cd_education_status,
    cd.cd_credit_rating,
    d_sale.d_year,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ws.web_name,
    ss.ss_net_paid,
    ss.ss_customer_sk
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY ss.ss_net_paid DESC
LIMIT 100
