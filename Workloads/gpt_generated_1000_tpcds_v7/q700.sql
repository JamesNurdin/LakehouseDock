WITH returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        sr.sr_returned_date_sk AS date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
)
SELECT
    d.d_year,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS store_sales_net_paid,
    SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
    SUM(ws.ws_net_paid) AS web_sales_net_paid,
    SUM(r.total_return_amt) AS total_return_amount,
    AVG(i.i_current_price) AS avg_item_price
FROM returns_agg r
JOIN item i
    ON r.item_sk = i.i_item_sk
JOIN date_dim d
    ON r.date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND p.p_channel_email = 'N'
  AND i.i_current_price BETWEEN 20 AND 100
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY d.d_year, p.p_promo_name
HAVING SUM(ss.ss_net_paid) > 5000
