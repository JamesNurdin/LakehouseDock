WITH cat_agg AS (
    SELECT
        d_cat.d_year,
        d_cat.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        AVG(cs.cs_ext_discount_amt) AS catalog_avg_discount
    FROM catalog_sales cs
    JOIN date_dim d_cat
        ON cs.cs_sold_date_sk = d_cat.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d_cat.d_year = 2001
    GROUP BY d_cat.d_year, d_cat.d_month_seq, i.i_category
),
web_agg AS (
    SELECT
        d_web.d_year,
        d_web.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        AVG(ws.ws_ext_discount_amt) AS web_avg_discount
    FROM web_sales ws
    JOIN date_dim d_web
        ON ws.ws_sold_date_sk = d_web.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE d_web.d_year = 2001
    GROUP BY d_web.d_year, d_web.d_month_seq, i.i_category
)
SELECT
    cat_agg.d_year,
    cat_agg.d_month_seq,
    cat_agg.i_category,
    cat_agg.catalog_net_paid,
    web_agg.web_net_paid,
    cat_agg.catalog_net_paid + web_agg.web_net_paid AS total_net_paid,
    cat_agg.catalog_net_profit,
    web_agg.web_net_profit,
    cat_agg.catalog_net_profit + web_agg.web_net_profit AS total_net_profit,
    cat_agg.catalog_avg_discount,
    web_agg.web_avg_discount
FROM cat_agg
FULL OUTER JOIN web_agg
    ON cat_agg.d_year = web_agg.d_year
   AND cat_agg.d_month_seq = web_agg.d_month_seq
   AND cat_agg.i_category = web_agg.i_category
ORDER BY cat_agg.d_year, cat_agg.d_month_seq, cat_agg.i_category
