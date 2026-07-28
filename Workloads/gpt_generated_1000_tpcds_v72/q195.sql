WITH sales_agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        cc.cc_name AS call_center_name,
        p.p_promo_name,
        MIN(ws.web_name) AS website_name,
        MIN(cp.cp_type) AS catalog_page_type,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store s                  ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_site ws              ON ws.web_open_date_sk = d.d_date_sk
    JOIN customer c              ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca     ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 1999
      AND cs.cs_quantity > 5
      AND p.p_discount_active = 'Y'
    GROUP BY GROUPING SETS (
        (d.d_year, s.s_store_name, cc.cc_name, p.p_promo_name),
        (d.d_year, s.s_store_name, cc.cc_name),
        (d.d_year, s.s_store_name),
        (d.d_year)
    )
    HAVING SUM(cs.cs_net_profit) > 1000
),

returns_agg AS (
    SELECT
        d.d_year,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(wr.wr_net_loss) DESC) AS loss_rank
    FROM web_returns wr
    JOIN date_dim d               ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r                 ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c               ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 1999
      AND wr.wr_return_quantity > 0
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY ROLLUP (d.d_year, r.r_reason_desc)
),

combined AS (
    SELECT
        'sales'   AS activity_type,
        s.d_year,
        s.s_store_name,
        s.call_center_name,
        s.p_promo_name,
        s.total_profit AS amount,
        s.sales_cnt    AS cnt,
        s.profit_rank  AS rank
    FROM sales_agg s
    UNION ALL
    SELECT
        'returns' AS activity_type,
        r.d_year,
        NULL      AS s_store_name,
        NULL      AS call_center_name,
        NULL      AS p_promo_name,
        -r.total_loss AS amount,
        r.returns_cnt AS cnt,
        r.loss_rank   AS rank
    FROM returns_agg r
)
SELECT
    activity_type,
    d_year,
    s_store_name,
    call_center_name,
    p_promo_name,
    amount,
    cnt,
    rank,
    (SELECT COUNT(*) FROM catalog_page WHERE cp_type = 'C') AS total_catalog_pages
FROM combined
WHERE amount > 0
ORDER BY d_year DESC, amount DESC
LIMIT 100
