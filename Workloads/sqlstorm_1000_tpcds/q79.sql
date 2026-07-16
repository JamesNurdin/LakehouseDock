WITH
catalog_sales_fact AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_sk,
        cs.cs_ext_sales_price AS sales_price,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        p.p_cost AS promo_cost,
        sm.sm_type AS ship_type,
        cc.cc_gmt_offset AS cc_gmt_offset,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
),
store_sales_fact AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_sk,
        ss.ss_ext_sales_price AS sales_price,
        ss.ss_net_profit AS profit,
        ss.ss_ext_discount_amt AS discount,
        p.p_cost AS promo_cost,
        NULL AS ship_type,
        NULL AS cc_gmt_offset,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS return_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_store_sk = sr.sr_store_sk
),
web_sales_fact AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_sk,
        ws.ws_ext_sales_price AS sales_price,
        ws.ws_net_profit AS profit,
        ws.ws_ext_discount_amt AS discount,
        p.p_cost AS promo_cost,
        sm.sm_type AS ship_type,
        NULL AS cc_gmt_offset,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS return_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
),
channel_union AS (
    SELECT * FROM catalog_sales_fact
    UNION ALL
    SELECT * FROM store_sales_fact
    UNION ALL
    SELECT * FROM web_sales_fact
),
monthly_agg AS (
    SELECT
        d_year,
        month_seq,
        i_category,
        i_class,
        i_brand,
        COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
        SUM(sales_price) AS total_sales,
        SUM(profit) AS total_profit,
        SUM(discount) AS total_discount,
        SUM(promo_cost) AS total_promo_cost,
        SUM(return_amount) AS total_returns,
        SUM(return_loss) AS total_return_loss,
        (SUM(sales_price) - COALESCE(SUM(return_amount), 0)) AS net_sales,
        (SUM(profit) - COALESCE(SUM(return_loss), 0)) AS net_profit
    FROM channel_union
    GROUP BY d_year, month_seq, i_category, i_class, i_brand
),
rolling_profit AS (
    SELECT
        d_year,
        month_seq,
        i_category,
        i_class,
        i_brand,
        distinct_items_sold,
        total_sales,
        total_profit,
        total_discount,
        total_promo_cost,
        total_returns,
        total_return_loss,
        net_sales,
        net_profit,
        AVG(net_profit) OVER (
            PARTITION BY i_category, i_class, i_brand
            ORDER BY d_year, month_seq
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS three_month_moving_avg_profit,
        ROW_NUMBER() OVER (
            PARTITION BY d_year
            ORDER BY net_profit DESC
        ) AS profit_rank_by_year
    FROM monthly_agg
)
SELECT
    d_year,
    month_seq,
    i_category,
    i_class,
    i_brand,
    distinct_items_sold,
    total_sales,
    total_profit,
    total_discount,
    total_promo_cost,
    total_returns,
    total_return_loss,
    net_sales,
    net_profit,
    three_month_moving_avg_profit,
    profit_rank_by_year
FROM rolling_profit
WHERE profit_rank_by_year <= 10
ORDER BY d_year, month_seq, net_profit DESC
LIMIT 200
