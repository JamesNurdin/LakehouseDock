WITH store_agg AS (
   SELECT
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_qty
   FROM store_sales ss
   JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 1998 AND 1999
     AND i.i_current_price BETWEEN 10 AND 100
     AND p.p_discount_active = 'Y'
   GROUP BY d.d_year, i.i_category
),

web_agg AS (
   SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_qty
   FROM web_sales ws
   TABLESAMPLE BERNOULLI (10)
   JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i                    ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p               ON ws.ws_promo_sk = p.p_promo_sk
   JOIN customer c                ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca       ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 1998 AND 1999
     AND i.i_current_price > 20
     AND p.p_discount_active = 'Y'
   GROUP BY d.d_year, i.i_category
),

union_agg AS (
   SELECT * FROM store_agg
   UNION DISTINCT
   SELECT * FROM web_agg
),

returns_full AS (
   SELECT
        cr.cr_item_sk,
        cr.cr_return_amount,
        wr.wr_item_sk,
        wr.wr_return_amt
   FROM catalog_returns cr
   FULL OUTER JOIN web_returns wr
        ON cr.cr_item_sk = wr.wr_item_sk
),

final AS (
   SELECT
        ua.d_year,
        ua.i_category,
        ua.total_net_paid,
        ua.total_qty,
        CASE WHEN ua.total_net_paid > 5000 THEN 'HIGH' ELSE 'LOW' END AS net_level,
        (
           SELECT SUM(cr2.cr_return_amount)
           FROM catalog_returns cr2
           WHERE cr2.cr_item_sk = i.i_item_sk
        ) AS total_return_amount
   FROM union_agg ua
   JOIN item i ON i.i_category = ua.i_category
   WHERE ua.total_qty > 100
     AND ua.total_net_paid > 1000
     AND ua.d_year = 1998
)
SELECT
    f.d_year,
    f.i_category,
    f.total_net_paid,
    f.total_qty,
    f.net_level,
    f.total_return_amount
FROM final f
ORDER BY f.total_net_paid DESC
LIMIT 100
