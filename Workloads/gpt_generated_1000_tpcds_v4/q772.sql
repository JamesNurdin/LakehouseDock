WITH base AS (
    SELECT
        ss.ss_net_paid,
        i.i_category,
        i.i_item_desc,
        i.i_formulation,
        d.d_year,
        w.web_street_name,
        cd.cd_gender
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_formulation, '^\\d{9,}$')
      AND w.web_street_name LIKE '%Hill%'
      AND cd.cd_gender = 'M'
      AND d.d_year BETWEEN 2000 AND 2002
),
agg AS (
    SELECT
        i_category,
        d_year,
        sum(ss_net_paid) AS total_net_paid,
        count(*) AS transaction_cnt,
        max(i_item_desc) AS i_item_desc
    FROM base
    GROUP BY i_category, d_year
)
SELECT
    i_category,
    d_year,
    total_net_paid,
    transaction_cnt,
    CASE
        WHEN total_net_paid > 100000 THEN 'High'
        WHEN total_net_paid > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_level,
    concat('Category: ', i_category) AS category_label,
    regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word_desc
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
