WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        d.d_year,
        t.t_hour,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn_customer_latest_sale
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND ss.ss_sales_price > 20
      AND cd.cd_credit_rating = 'Good'
      AND t.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    sa.ss_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.cd_gender,
    sa.cd_credit_rating,
    SUM(sa.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
    RANK() OVER (ORDER BY SUM(sa.ss_ext_sales_price) DESC) AS sales_rank
FROM sales_agg sa
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sa.ss_ticket_number
   AND sr.sr_item_sk = sa.ss_item_sk
   AND sr.sr_customer_sk = sa.ss_customer_sk
   AND sr.sr_cdemo_sk = sa.ss_cdemo_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = sa.ss_sold_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = sa.ss_sold_date_sk
   AND ws.ws_bill_customer_sk = sa.ss_customer_sk
LEFT JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
GROUP BY
    sa.ss_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.cd_gender,
    sa.cd_credit_rating
HAVING
    SUM(sa.ss_ext_sales_price) > 5000
ORDER BY
    sales_rank
LIMIT 100
