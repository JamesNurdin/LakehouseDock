WITH base_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        i.i_item_id,
        i.i_brand,
        p.p_promo_name,
        td_sold.t_sub_shift,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    LEFT JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    WHERE cp.cp_department = 'Sports'
      AND i.i_brand = 'BrandA'
      AND p.p_promo_name LIKE '%Clearance%'
      AND td_sold.t_sub_shift = 'morning'
      AND cs.cs_quantity > 0
      AND cs.cs_sales_price > 500
      AND (cr.cr_return_amount > 0 OR cr.cr_return_amount IS NULL)
      AND (wr.wr_return_amt > 0 OR wr.wr_return_amt IS NULL)
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        i.i_item_id,
        i.i_brand,
        p.p_promo_name,
        td_sold.t_sub_shift
    HAVING SUM(cs.cs_quantity) > 10
       AND SUM(cs.cs_net_paid_inc_ship_tax) > 1000
)
SELECT
    ba.cp_catalog_page_id,
    ba.cp_department,
    ba.i_item_id,
    ba.i_brand,
    ba.p_promo_name,
    ba.t_sub_shift,
    ba.total_quantity,
    ba.total_sales,
    ba.net_profit,
    AVG(ba.net_profit) OVER (PARTITION BY ba.cp_department) AS avg_dept_net_profit,
    ROW_NUMBER() OVER (PARTITION BY ba.cp_department ORDER BY ba.net_profit DESC) AS dept_net_profit_rank
FROM base_agg ba
ORDER BY avg_dept_net_profit DESC, ba.net_profit DESC
LIMIT 100
