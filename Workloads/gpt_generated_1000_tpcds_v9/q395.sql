WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
),

sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_sk,
        s.s_market_id,
        d_sold.d_date,
        d_sold.d_year,
        i.i_item_id,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS total_net_profit,
        SUM(CASE WHEN p_ss.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_count,
        SUM(CASE WHEN hd_ss.hd_buy_potential = '5001-10000' THEN 1 ELSE 0 END) AS high_buy_potential_count
    FROM
        store s
        LEFT JOIN sampled_store_sales ss
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN date_dim d_sold
            ON ss.ss_sold_date_sk = d_sold.d_date_sk
        LEFT JOIN time_dim t_sold
            ON ss.ss_sold_time_sk = t_sold.t_time_sk
        LEFT JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN customer_demographics cd_ss
            ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        LEFT JOIN household_demographics hd_ss
            ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        LEFT JOIN promotion p_ss
            ON ss.ss_promo_sk = p_ss.p_promo_sk
        LEFT JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
            AND cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p_cs
            ON cs.cs_promo_sk = p_cs.p_promo_sk
        LEFT JOIN warehouse w_cs
            ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        LEFT JOIN customer_demographics cd_cs_bill
            ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
        LEFT JOIN household_demographics hd_cs_bill
            ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_date_sk = d_sold.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
        LEFT JOIN promotion p_ws
            ON ws.ws_promo_sk = p_ws.p_promo_sk
        LEFT JOIN warehouse w_ws
            ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        LEFT JOIN customer_demographics cd_ws_bill
            ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
        LEFT JOIN household_demographics hd_ws_bill
            ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
        LEFT JOIN date_dim d_return
            ON cr.cr_returned_date_sk = d_return.d_date_sk
        LEFT JOIN household_demographics hd_refund
            ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
        LEFT JOIN customer_demographics cd_refund
            ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
        LEFT JOIN warehouse w_cr
            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    WHERE
        d_sold.d_year = 2001
        AND s.s_market_id IN (3, 5, 7)
        AND i.i_current_price BETWEEN 50 AND 200
        AND p_ss.p_discount_active = 'Y'
        AND hd_ss.hd_buy_potential = '5001-10000'
        AND EXISTS (
            SELECT 1
            FROM promotion p_check
            WHERE p_check.p_promo_sk = p_ss.p_promo_sk
              AND p_check.p_discount_active = 'Y'
        )
    GROUP BY
        s.s_store_id,
        s.s_store_sk,
        s.s_market_id,
        d_sold.d_date,
        d_sold.d_year,
        i.i_item_id
)
SELECT
    sa.s_store_id,
    sa.s_market_id,
    sa.d_date,
    sa.i_item_id,
    sa.store_sales,
    sa.catalog_sales,
    sa.web_sales,
    sa.return_amount,
    sa.total_net_profit,
    CASE
        WHEN sa.s_market_id IS NULL THEN 'Unknown Market'
        ELSE CAST(sa.s_market_id AS VARCHAR)
    END AS market_id_str,
    ds.distinct_items_sold,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank_by_year
FROM
    sales_agg sa
    CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT ss2.ss_item_sk) AS distinct_items_sold
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = sa.s_store_sk
    ) ds
ORDER BY
    sa.total_net_profit DESC
LIMIT 100
