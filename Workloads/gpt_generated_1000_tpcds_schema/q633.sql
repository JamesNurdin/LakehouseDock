WITH
    sample_ss AS (
        SELECT *
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    intersect_keys AS (
        SELECT ss_ticket_number AS ticket
        FROM sample_ss
        INTERSECT
        SELECT cs_order_number
        FROM catalog_sales
    ),
    except_keys AS (
        SELECT ss_ticket_number AS ticket
        FROM sample_ss
        EXCEPT
        SELECT cs_order_number
        FROM catalog_sales
    ),
    unnest_metrics AS (
        SELECT ss_ticket_number,
               val
        FROM sample_ss
        CROSS JOIN UNNEST(ARRAY[CAST(ss_quantity AS double), CAST(ss_wholesale_cost AS double)]) AS t(val)
    ),
    joined AS (
        SELECT
            s.s_state,
            p.p_promo_name,
            td.t_hour,
            r.r_reason_desc,
            ss.ss_net_paid,
            cs.cs_ext_sales_price,
            sr.sr_return_tax,
            CASE WHEN sr.sr_return_tax > 100 THEN 'High' ELSE 'Low' END AS tax_level,
            um.val AS metric_value,
            ik.ticket AS intersect_ticket,
            ek.ticket AS except_ticket
        FROM sample_ss ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
                               AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN intersect_keys ik ON ss.ss_ticket_number = ik.ticket
        LEFT JOIN except_keys ek ON ss.ss_ticket_number = ek.ticket
        LEFT JOIN unnest_metrics um ON ss.ss_ticket_number = um.ss_ticket_number
        WHERE
            td.t_time IN (10, 14)
            AND cd.cd_gender = 'M'
            AND hd.hd_buy_potential = '1001-5000'
            AND s.s_state = 'CA'
            AND p.p_discount_active = 'Y'
            AND r.r_reason_desc LIKE '%damaged%'
    )
SELECT
    s_state,
    p_promo_name,
    t_hour,
    r_reason_desc,
    COUNT(DISTINCT tax_level) AS tax_level_count,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(cs_ext_sales_price) AS avg_ext_sales_price,
    MIN(sr_return_tax) AS min_return_tax,
    MAX(sr_return_tax) AS max_return_tax,
    COUNT(*) AS transaction_count
FROM joined
GROUP BY
    s_state,
    p_promo_name,
    t_hour,
    r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
