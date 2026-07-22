WITH sales_returns_agg AS (
    SELECT
        cd.cd_gender,
        hd.hd_buy_potential,
        td.t_sub_shift,
        r.r_reason_desc,
        CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions,
        COUNT(DISTINCT wr.wr_order_number) AS num_return_transactions
    FROM
        store_sales ss
        JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN web_returns wr
            ON wr.wr_returned_time_sk = td.t_time_sk
            AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
            AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
        JOIN reason r
            ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        td.t_sub_shift IN ('morning', 'afternoon')
        AND ss.ss_quantity > 1
        AND wr.wr_account_credit > 100
    GROUP BY
        cd.cd_gender,
        hd.hd_buy_potential,
        td.t_sub_shift,
        r.r_reason_desc,
        CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END
)
SELECT
    cd_gender,
    hd_buy_potential,
    t_sub_shift,
    r_reason_desc,
    marital_category,
    total_sales,
    total_returns,
    total_net_profit,
    total_net_loss,
    total_sales - total_net_loss AS net_sales_after_loss,
    CASE WHEN total_returns = 0 THEN NULL ELSE total_sales / total_returns END AS sales_to_return_ratio,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM
    sales_returns_agg
WHERE
    total_sales > (SELECT AVG(total_sales) FROM sales_returns_agg)
ORDER BY
    total_sales DESC
