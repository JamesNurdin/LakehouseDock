WITH sales_by_page AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_description,
        d_sold.d_year,
        d_sold.d_month_seq,
        cc.cc_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        CASE
            WHEN SUM(cs.cs_net_profit) > 20000 THEN 'High'
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        REGEXP_EXTRACT(cp.cp_description, '(?i)(Economic|Legal|National|Poor)', 1) AS extracted_term
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    WHERE REGEXP_LIKE(cp.cp_description, '(?i)economic')
      AND cc.cc_manager LIKE '%Smith%'
    GROUP BY cp.cp_catalog_page_id, cp.cp_description, d_sold.d_year, d_sold.d_month_seq, cc.cc_name
)
SELECT
    s.cp_catalog_page_id,
    CONCAT(s.cp_catalog_page_id, ': ', SUBSTRING(s.cp_description, 1, 30)) AS page_label,
    SUBSTRING(s.cp_description, 1, 30) AS short_desc,
    s.extracted_term,
    s.d_year,
    s.d_month_seq,
    s.cc_name,
    s.total_profit,
    s.profit_category,
    ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS rn
FROM sales_by_page s
WHERE s.total_quantity > (
    SELECT AVG(sb.total_quantity) FROM sales_by_page sb
)
ORDER BY s.total_profit DESC
LIMIT 50
