WITH sales_web AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_bill_hdemo_sk,
        d.d_year,
        d.d_date,
        w.web_mkt_desc,
        hd.hd_buy_potential
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(w.web_mkt_desc, '^Deeply')
      AND hd.hd_buy_potential LIKE '%1000%'
)
SELECT
    d_year,
    regexp_extract(web_mkt_desc, '^(\\w+)', 1) AS market_first_word,
    sum(cs_net_profit) AS total_profit,
    count(*) AS sales_cnt
FROM sales_web
GROUP BY d_year, regexp_extract(web_mkt_desc, '^(\\w+)', 1)
ORDER BY total_profit DESC
LIMIT 100
